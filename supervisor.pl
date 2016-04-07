#! /usr/bin/perl

use strict;
use warnings;
use v5.10;
use FindBin;
use lib $FindBin::Bin;
use okzbx::Utils;


our $arg_discovery;
our $arg_check;
our $arg_status;
while (scalar @ARGV)
{
	my $arg = shift;
	if ($arg =~ /^\-d|\-\-discovery$/)
	{
		$arg_discovery = 1;
	}
	elsif ($arg =~ /^\-c|\-\-check$/)
	{
		$arg_check = 1;
	}
	elsif ($arg =~ /^\-s|\-\-status$/)
	{
		$arg_status = shift;
	}
	else
	{
		die "Bad input argument $arg";
	}
}
die "There are missed argument(s)" if
	not defined $arg_discovery and
	not defined $arg_check and
	not defined $arg_status;
	
sub getStatuses
{
	return undef if not -e '/usr/bin/supervisorctl';
	my $result = {};
	for (`/usr/bin/supervisorctl status`)
	{
		my ($name, $status) = m/^\s*(\S+)\s+(\S+)\s+.*$/;
		$result->{$name} = $status;
	}
	return $result;
}

sub discovery
{
	my $statuses = getStatuses;
	return 0 if not defined $statuses;
	my @names = keys %$statuses;
	printDiscoveryHead;
	for (@names)
	{
		printDiscoveryItem {'NAME' => $_};
	}
	printDiscoveryEnd;
	return 1;
}

sub check
{
	return 0 if not -e '/usr/bin/supervisorctl';
	system 'pgrep -f "/usr/bin/python /usr/bin/supervisord" >/dev/null 2>&1';
	say $?? 0: 1;
	return 1;
}

sub status
{
	my $statuses = getStatuses;
	return 0 if not defined $statuses;
	my @names = keys %$statuses;
	for (@names)
	{
		if ($_ eq $arg_status)
		{
			say $statuses->{$_};
			return 1;
		}
	}
	return 0;
}

exit (discovery()? 0: 1) if $arg_discovery;
exit (check()? 0: 1) if $arg_check;
exit (status()? 0: 1) if $arg_status;
