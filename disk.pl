#! /usr/bin/perl

=Copyright
    Copyright (C) 2016  Orkun Karaduman <orkunkaraduman@gmail.com>
=GPLv3
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

use strict;
use warnings;
use v5.10;
use FindBin;
use lib $FindBin::Bin;
use okzbx::Utils;


our $arg_discovery;
while (scalar @ARGV)
{
	my $arg = shift;
	if ($arg =~ /^\-d|\-\-discovery$/)
	{
		$arg_discovery = shift;
	}
	else
	{
		die "Bad input argument $arg";
	}
}
die "There are missed argument(s)" if
	not defined $arg_discovery;

sub discovery
{
	printDiscoveryHead;
	for (`lsblk -iblo KNAME,TYPE,MAJ:MIN,SIZE,FSTYPE`)
	{
		my ($disk,$type,$major,$minor,$size,$fstype) = m/^\s*(\S+)\s+(\S+)\s+([^\s:]+):([^\s:]+)\s+(\S+)\s+(\S+)?/;
		$fstype = "" if not defined $fstype;
		next if ($disk eq 'KNAME' && $type eq 'TYPE');
		if ('disk' eq $arg_discovery)
		{
			next if ($type ne 'disk');
		} elsif ('fs' eq $arg_discovery)
		{
			next if (not defined $fstype);
		}
		my $dmnamefile = "/sys/dev/block/$major:$minor/dm/name";
		my $dmname = $disk;
		my $diskdev = "/dev/$disk";
		if (-e $dmnamefile)
		{
			$dmname = `cat $dmnamefile`;
			$dmname =~ s/\n$//;
			$diskdev = "/dev/mapper/$dmname";
		}
		printDiscoveryItem {
			'DISK' => $disk,
			'DISKDEV' => $diskdev,
			'DMNAME' => $dmname,
			'SIZE' => $size,
			'FSTYPE' => $fstype
		};
	}
	printDiscoveryEnd;
}

exit (discovery()? 0: 1) if $arg_discovery;
