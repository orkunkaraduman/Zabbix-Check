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

package okzbx::Utils;

use strict;
use warnings;
use v5.10;
use Exporter qw(import);


sub ltrim { my $s = shift; $s =~ s/^\s+//;       return $s };

sub rtrim { my $s = shift; $s =~ s/\s+$//;       return $s };

sub  trim { my $s = shift; $s =~ s/^\s+|\s+$//g; return $s };

sub printDiscoveryHead
{
	print "{\n";
	print "\t\"data\":[\n";
}

sub printDiscoveryItem
{
	my ($item) = @_;
	state $first = 1;
	print "\t\t,\n" if not $first;
	$first = 0;
	print "\t\t{";
	my $first2 = 1;
	for my $key (keys %$item)
	{
		my $val = $item->{$key};
		print "," if not $first2;
		print "\n\t\t\t\"{#$key}\":\"$val\"";
		$first2 = 0;
	}
	print "\n\t\t}\n";
}

sub printDiscoveryEnd
{
	print "\t]\n";
	print "}\n";
}


our @EXPORT_OK = qw(ltrim rtrim trim printDiscoveryHead printDiscoveryItem printDiscoveryEnd);
our @EXPORT = @EXPORT_OK;

return 1;
