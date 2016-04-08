#! /usr/bin/perl

use strict;
use warnings;
use v5.10;
use okzbx::Utils;

printDiscoveryHead;
printDiscoveryItem {'a' => 'x', 'b' => 'y'};
printDiscoveryItem {'c' => 'z', 'd' => 'f'};
printDiscoveryEnd;

exit 0;
