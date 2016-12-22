package Zabbix::Check::Disk;
=head1 NAME

Zabbix::Check::Disk - Zabbix check for disk

=head1 VERSION

version 1.06

=head1 SYNOPSIS

Zabbix check for disk

	UserParameter=cpan.zabbix.check.disk.discovery,/usr/bin/perl -MZabbix::Check::Disk -e_discovery
	UserParameter=cpan.zabbix.check.disk.bps[*],/usr/bin/perl -MZabbix::Check::Disk -e_bps $1 $2
	UserParameter=cpan.zabbix.check.disk.iops[*],/usr/bin/perl -MZabbix::Check::Disk -e_iops $1 $2
	UserParameter=cpan.zabbix.check.disk.ioutil[*],/usr/bin/perl -MZabbix::Check::Disk -e_ioutil $1 $2

=head3 discovery

discovers disks

=head3 bps $1 $2

gets disk I/O traffic in bytes per second

$1: I<device name eg: sda, sdb1, dm-3, ...>

$2: I<type: read|write|total>

=head3 iops $1 $2

gets disk I/O transaction speed in transactions per second

$1: I<device name eg: sda, sdb1, dm-3, ...>

$2: I<type: read|write|total>

=head3 ioutil $1 $2

gets disk I/O utilization in percentage

$1: I<device name eg: sda, sdb1, dm-3, ...>

$2: I<type: read|write|total>

=cut
use strict;
use warnings;
no warnings qw(qw utf8);
use v5.14;
use utf8;
use File::Slurp;
use JSON;

use Zabbix::Check;


BEGIN
{
	require Exporter;
	# set the version for version checking
	our $VERSION     = '1.06';
	# Inherit from Exporter to export functions and variables
	our @ISA         = qw(Exporter);
	# Functions and variables which are exported by default
	our @EXPORT      = qw(_discovery _bps _iops _ioutil);
	# Functions and variables which can be optionally exported
	our @EXPORT_OK   = qw();
}


sub disks
{
	my $result = {};
	for my $blockpath (glob("/sys/dev/block/*"))
	{
		next unless -f "$blockpath/uevent";
		my $uevent = read_file("$blockpath/uevent");
		my ($major) = $uevent =~ /^\QMAJOR=\E(.*)/m;
		my ($minor) = $uevent =~ /^\QMINOR=\E(.*)/m;
		my ($devname) = $uevent =~ /^\QDEVNAME=\E(.*)/m;
		my ($devtype) = $uevent =~ /^\QDEVTYPE=\E(.*)/m;
		my $devpath = "/dev/$devname";
		my $disk = {
			blockpath => $blockpath,
			devname => $devname,
			devtype => $devtype,
			devpath => $devpath,
			major => $major,
			minor => $minor,
			size => (-f "$blockpath/size" and $_ = read_file("$blockpath/size"))? int(s/^\s+|\s+$//gr)*512: undef,
			removable => (-f "$blockpath/removable" and $_ = read_file("$blockpath/removable"))? s/^\s+|\s+$//gr: undef,
			partition => (-f "$blockpath/partition" and $_ = read_file("$blockpath/partition"))? s/^\s+|\s+$//gr: undef,
			dmname => undef,
			dmpath => undef,
		};
		if (-f "$blockpath/dm/name" and my $dmname = read_file("$blockpath/dm/name"))
		{
			chomp $dmname;
			$disk->{dmname} = $dmname;
			$disk->{dmpath} = "/dev/mapper/$dmname";
		}
		my $dmpath = $disk->{dmpath}? $disk->{dmpath}: "";
		for my $mount (grep(/^(\Q$disk->{devpath}\E|\Q$dmpath\E)\s+/, (-f "/proc/mounts")? read_file("/proc/mounts"): ()))
		{
			chomp $mount;
			my ($devpath, $mountpoint, $fstype) = $mount =~ /^(\S+)\s+(\S+)\s+(\S+)\s+/;
			$disk->{fstype} = $fstype;
		}
		$result->{$devname} = $disk;
	}
	return $result;
}

sub stats
{
	my $result = {};
	my $disks = disks();
	for my $devname (keys %$disks)
	{
		my $disk = $disks->{$devname};
		next unless -f "$disk->{blockpath}/stat";
		my $statLine = read_file("$disk->{blockpath}/stat");
		next unless $statLine;
		chomp $statLine;
		my $stat = { 'epoch' => time() };
		(
			$stat->{readsCompleted},
			$stat->{readsMerged},
			$stat->{sectorsRead},
			$stat->{timeSpentReading},
			$stat->{writesCompleted},
			$stat->{writesMerged},
			$stat->{sectorsWritten},
			$stat->{timeSpentWriting},
			$stat->{IOsCurrently},
			$stat->{timeSpentIOs},
			$stat->{weightedTimeSpentIOs},
		) = $statLine =~ /^\s*(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)/;
		$result->{$devname} = $stat;
	}
	return $result;
}

sub analyzeStats
{
	my $now = time();
	my $stats;
	my $oldStats;
	my $tmpPrefix = "/tmp/".__PACKAGE__ =~ s/\Q::\E/-/gr.".analyzeStats.";
	for my $tmpPath (sort {$b cmp $a} glob("$tmpPrefix*"))
	{
		if (my ($epoch, $pid) = $tmpPath =~ /^\Q$tmpPrefix\E(\d*)\.(\d*)/) 
		{
			my $tmp = read_file($tmpPath);
			if ($now-$epoch < 1*60)
			{
				eval { $stats = from_json($tmp) } if not $stats and $tmp;
				next;
			}
			if (not $oldStats and $tmp)
			{
				eval { $oldStats = from_json($tmp) };
				next unless $@;
			}
			unlink($tmpPath) if $now-$epoch > 2*60;
			next;
		}
		unlink($tmpPath);
	}
	unless ($stats)
	{
		$stats = stats();
		write_file("$tmpPrefix$now.$$", to_json($stats, {pretty => 1}));
	}
	return unless $oldStats;
	my $result = {};
	for my $devname (keys %$stats)
	{
		my $stat = $stats->{$devname};
		my $oldStat = $oldStats->{$devname};
		next unless defined $oldStat;
		my $diff = $stat->{epoch} - $oldStat->{epoch};
		next unless $diff;
		$result->{$devname} = {};

		my $rw;
		my $io;

		$rw = $stat->{sectorsRead} - $oldStat->{sectorsRead};
		$io = $stat->{readsCompleted} - $oldStat->{readsCompleted};
		$result->{$devname}->{bps_read} = 512*$rw/$diff;
		$result->{$devname}->{iops_read} = $io/$diff;
		$result->{$devname}->{ioutil_read} = $rw? 100*$io/$rw: 0;

		$rw = $stat->{sectorsWritten} - $oldStat->{sectorsWritten};
		$io = $stat->{writesCompleted} - $oldStat->{writesCompleted};
		$result->{$devname}->{bps_write} = 512*$rw/$diff;
		$result->{$devname}->{iops_write} = $io/$diff;
		$result->{$devname}->{ioutil_write} = $rw? 100*$io/$rw: 0;

		$rw = $stat->{sectorsRead} - $oldStat->{sectorsRead} + $stat->{sectorsWritten} - $oldStat->{sectorsWritten};
		$io = $stat->{readsCompleted} - $oldStat->{readsCompleted} + $stat->{writesCompleted} - $oldStat->{writesCompleted};
		$result->{$devname}->{bps_total} = 512*$rw/$diff;
		$result->{$devname}->{iops_total} = $io/$diff;
		$result->{$devname}->{ioutil_total} = $rw? 100*$io/$rw: 0;
	}
	return $result;
}

sub _discovery
{
	my ($removable) = @_;
	my @items;
	my $disks = disks();
	for my $devname (keys %$disks)
	{
		my $disk = $disks->{$devname};
		next if not $removable and $disk->{removable};
		push @items, $disk;
	}
	return printDiscovery(@items);
}

sub _bps
{
	my ($devname, $type) = map(zbxDecode($_), @ARGV);
	return unless $devname and $type and $type =~ /^read|write|total$/;
	my $result = 0;
	my $analyzed = analyzeStats();
	my $status = $analyzed->{$devname} if $analyzed;
	$result = $status->{"bps_$type"} if $status;
	print $result;
	return $result;
}

sub _iops
{
	my ($devname, $type) = map(zbxDecode($_), @ARGV);
	return unless $devname and $type and $type =~ /^read|write|total$/;
	my $result = 0;
	my $analyzed = analyzeStats();
	my $status = $analyzed->{$devname} if $analyzed;
	$result = $status->{"iops_$type"} if $status;
	print $result;
	return $result;
}

sub _ioutil
{
	my ($devname, $type) = map(zbxDecode($_), @ARGV);
	return unless $devname and $type and $type =~ /^read|write|total$/;
	my $result = 0;
	my $analyzed = analyzeStats();
	my $status = $analyzed->{$devname} if $analyzed;
	$result = $status->{"ioutil_$type"} if $status;
	print $result;
	return $result;
}


1;
__END__
=head1 REPOSITORY

B<GitHub> L<https://github.com/orkunkaraduman/Zabbix-Check>

B<CPAN> L<https://metacpan.org/release/Zabbix-Check>

=head1 AUTHOR

Orkun Karaduman <orkunkaraduman@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2016  Orkun Karaduman <orkunkaraduman@gmail.com>

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

=cut
