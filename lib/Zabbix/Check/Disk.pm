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
	no warnings qw(uninitialized);
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
		$result->{$devname} = {
			blockpath => $blockpath,
			devname => $devname,
			devtype => $devtype,
			devpath => $devpath,
			major => $major,
			minor => $minor,
			size => (-f "$blockpath/size")? int(read_file("$blockpath/size") =~ s/^\s+|\s+$//gr)*512: undef,
			removable => (-f "$blockpath/removable")? read_file("$blockpath/removable") =~ s/^\s+|\s+$//gr: undef,
			partition => (-f "$blockpath/partition")? read_file("$blockpath/partition") =~ s/^\s+|\s+$//gr: undef,
			dmname => undef,
			dmpath => undef,
		};
		if ((-f "$blockpath/dm/name") and (my $dmname = read_file("$blockpath/dm/name")))
		{
			chomp $dmname;
			$result->{dmname} = $dmname;
			$result->{dmpath} = "/dev/mapper/$dmname";
		}
		for my $mount (grep(/^(\Q$result->{devpath}\E|\Q$result->{dmpath}\E)\s+/, (-f "/proc/mounts")? read_file("/proc/mounts"): ()))
		{
			chomp $mount;
			my ($devpath, $mountpoint, $fstype) = $mount =~ /^(\S+)\s+(\S+)\s+(\S+)\s+/;
			$result->{$devname}->{fstype} = $fstype;
		}
	}
	return $result;
}

sub discovery
{
	my ($removable) = @_;
	my @result;
	my $disks = disks();
	for my $devname (keys %$disks)
	{
		my $disk = $disks->{$devname};
		next if not $removable and $disk->{removable};
		push @result, $disk;
	}
	Zabbix::Check::printDiscovery(@result);
	return @result;
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
