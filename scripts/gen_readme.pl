#! /usr/bin/perl
use strict;
use warnings;
no warnings qw(qw utf8);
use v5.14;
use utf8;
use open qw(:std :locale);
use Config;
use FindBin;
use Cwd;


my $base = "${FindBin::Bin}/..";
cwd($base);


system('pod2markdown --html-encode-chars 1 lib/Zabbix/Check.pm > README.md');
system('pod2text lib/Zabbix/Check.pm > README');
system('git ls-files | grep -v "^\.gitignore" > MANIFEST');
