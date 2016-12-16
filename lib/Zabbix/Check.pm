package Zabbix::Check;
=head1 NAME

Zabbix::Check - Zabbix checks

=head1 VERSION

version 1.01

=head1 SYNOPSIS

Zabbix checks

=head1 INSTALLATION

To install this module type the following

	perl Makefile.PL
	make
	make test
	make install

from CPAN

	cpan -i Zabbix::Check

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
	our @EXPORT_OK   = qw(zbxEncode zbxDecode);
}


our @zbxSpecials = (qw(\ ' " ` * ? [ ] { } ~ $ ! & ; ( ) < > | # @), "\n");


sub zbxEncode
{
	my $result = "";
	my ($str) = @_;
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
	$result;
}

sub zbxDecode
{
	my $result = "";
	my ($str) = @_;
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
	$result;
}

sub printDiscovery
{
	my $result = {
		data => [
			map({
				my $item = $_; 
				{
					map({
						my $key = $_;
						my $val = $item->{$key};
						my $newkey = zbxEncode($key);
						$newkey = uc("{#$newkey}");
						$newkey => zbxEncode($val);
					} keys(%$item));
				};
			} @_),
		],
	};
	say to_json($result);
	return $result;
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
