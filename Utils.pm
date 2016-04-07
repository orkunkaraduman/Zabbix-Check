package okzbx::Utils;

use strict;
use warnings;


sub ltrim { my $s = shift; $s =~ s/^\s+//;       return $s };

sub rtrim { my $s = shift; $s =~ s/\s+$//;       return $s };

sub  trim { my $s = shift; $s =~ s/^\s+|\s+$//g; return $s };


return 1;
