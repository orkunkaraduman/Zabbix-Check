package Zabbix::Check;
=head1 NAME

Zabbix::Check - Zabbix checks

=head1 VERSION

version 1.01

=head1 SYNOPSIS

Zabbix checks

=head1 USAGE

=head2 Disk

C<UserParameter=cpan.zabbix.check.disk.discovery,/usr/bin/perl -MZabbix::Check::Disk -e_discovery
UserParameter=cpan.zabbix.check.disk.bps[*],/usr/bin/perl -MZabbix::Check::Disk -e_bps $1 $2
UserParameter=cpan.zabbix.check.disk.iops[*],/usr/bin/perl -MZabbix::Check::Disk -e_iops $1 $2
UserParameter=cpan.zabbix.check.disk.ioutil[*],/usr/bin/perl -MZabbix::Check::Disk -e_ioutil $1 $2>

=over

B<$1> Device name eg: sda, sdb1, dm-3, ...

B<$2> Type: read or write or total

=back

=head1 INSTALLATION

To install this module type the following

	perl Makefile.PL
	make
	make test
	make install

from CPAN

	cpan -i Zabbix::Check

=head1 DEPENDENCIES

This module requires these other modules and libraries:

=over

=item *

Switch

=item *

FindBin

=item *

Cwd

=item *

File::Basename

=item *

File::Slurp

=item *

JSON

=back

=cut
use strict;
use warnings;
no warnings qw(qw utf8);
use v5.14;
use utf8;
use Config;
use JSON;


BEGIN
{
	require Exporter;
	# set the version for version checking
	our $VERSION     = '1.01';
	# Inherit from Exporter to export functions and variables
	our @ISA         = qw(Exporter);
	# Functions and variables which are exported by default
	our @EXPORT      = qw(zbxEncode zbxDecode);
	# Functions and variables which can be optionally exported
	our @EXPORT_OK   = qw(printDiscovery whereisBin);
}


our @zbxSpecials = (qw(\ ' " ` * ? [ ] { } ~ $ ! & ; ( ) < > | # @), "\n");


sub zbxEncode
{
	my $result = "";
	my ($str) = @_;
	return $result unless $str;
	for (my $i = 0; $i < length $str; $i++)
	{
		my $chr = substr $str, $i, 1;
		if (grep ($_ eq $chr, (@zbxSpecials, '%')))
		{
			$result .= uc sprintf("%%%x", ord($chr));
		} else
		{
			$result .= $chr;
		}
	}
	return $result;
}

sub zbxDecode
{
	my $result = "";
	my ($str) = @_;
	return $result unless $str;
	my ($i, $len) = (0, length $str);
	while ($i < $len)
	{
		my $chr = substr $str, $i, 1;
		if ($chr eq '%')
		{
			return $result if $len-$i-1 < 2;
			$result .= chr(hex(substr($str, $i+1, 2)));
			$i += 2;
		} else
		{
			$result .= $chr;
		}
		$i++;
	}
	return $result;
}

sub printDiscovery
{
	my @items = @_;
	my $discovery = {
		data => [
			map({
				my $item = $_; 
				my %newitem = map({
					my $key = $_;
					my $val = $item->{$key};
					my $newkey = zbxEncode($key);
					$newkey = uc("{#$newkey}");
					my $newval = zbxEncode($val);
					$newkey => $newval;
				} keys(%$item));
				\%newitem;
			} @items),
		],
	};
	my $result = to_json($discovery, {pretty => 1});
	print $result;
	return $result;
}

sub whereisBin
{
	my ($name) = @_;
	return grep(-f $_, map("$_/$name", split(":", "/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin")));
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
