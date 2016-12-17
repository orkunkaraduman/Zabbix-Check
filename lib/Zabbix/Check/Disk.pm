package Zabbix::Check::Disk;
=head1 NAME

Zabbix::Check::Disk - Zabbix check disk

=head1 VERSION

version 1.01

=head1 SYNOPSIS

Zabbix check disk

=cut
use strict;
use warnings;
no warnings qw(qw utf8);
use v5.14;
use utf8;
use Config;
use FindBin;
use Cwd;
use File::Basename;
use File::Slurp;
use JSON;

use Zabbix::Check;


BEGIN
{
	require Exporter;
	# set the version for version checking
	our $VERSION     = '1.01';
	# Inherit from Exporter to export functions and variables
	our @ISA         = qw(Exporter);
	# Functions and variables which are exported by default
	our @EXPORT      = qw();
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
			if ($now-$epoch < 1*60)
			{
				unless ($stats)
				{
					$stats = stats();
					write_file("$tmpPrefix$now.$$", to_json($stats, {pretty => 1}));
				}
				next;
			}
			if (not $oldStats and my $tmp = read_file($tmpPath))
			{
				eval { $oldStats = from_json($tmp) };
				next unless $@;
			}
			unlink($tmpPath) if $now-$epoch > 2*60;
		} else
		{
			unlink($tmpPath);
		}
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
		$result->{$devname}->{read_bps} = 512*$rw/$diff;
		$result->{$devname}->{read_iops} = $io/$diff;
		$result->{$devname}->{read_ioutil} = $rw? 100*$io/$rw: 0;

		$rw = $stat->{sectorsWritten} - $oldStat->{sectorsWritten};
		$io = $stat->{writesCompleted} - $oldStat->{writesCompleted};
		$result->{$devname}->{write_bps} = 512*$rw/$diff;
		$result->{$devname}->{write_iops} = $io/$diff;
		$result->{$devname}->{write_ioutil} = $rw? 100*$io/$rw: 0;

		$rw = $stat->{sectorsRead} - $oldStat->{sectorsRead} + $stat->{sectorsWritten} - $oldStat->{sectorsWritten};
		$io = $stat->{readsCompleted} - $oldStat->{readsCompleted} + $stat->{writesCompleted} - $oldStat->{writesCompleted};
		$result->{$devname}->{total_bps} = 512*$rw/$diff;
		$result->{$devname}->{total_iops} = $io/$diff;
		$result->{$devname}->{total_ioutil} = $rw? 100*$io/$rw: 0;
	}
	return $result;
}

sub discovery
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
	return Zabbix::Check::printDiscovery(@items);
}


1;
__END__
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
