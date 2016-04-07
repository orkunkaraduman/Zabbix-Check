#! /usr/bin/perl

use strict;
use warnings;
use v5.10;
use okzbx::Utils;

printDiscoverHead;
printDiscoverItem {'a' => 'x', 'b' => 'y'};
printDiscoverItem {'c' => 'z', 'd' => 'f'};
printDiscoverEnd;

exit 0;
