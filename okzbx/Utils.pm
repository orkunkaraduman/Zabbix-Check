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
