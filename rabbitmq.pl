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


our $arg_type;
our $arg_discovery;
our $arg_status;
our $arg_vhost;
while (scalar @ARGV)
{
	my $arg = shift;
	if ($arg =~ /^\-t|\-\-type$/)
	{
		$arg_type = shift;
	}
	elsif ($arg =~ /^\-d|\-\-discovery$/)
	{
		$arg_discovery = 1;
	}
	elsif ($arg =~ /^\-s|\-\-status$/)
	{
		$arg_status = shift;
	}
	elsif ($arg =~ /^\-v|\-\-vhost$/)
	{
		$arg_vhost = shift;
	}
	else
	{
		die "Bad input argument $arg";
	}
}
die "There are missed argument(s)" if
	not defined $arg_type; # or
#	(
#	not defined $arg_discovery and
#	not defined $arg_status
#	);

sub getQueues
{
	return undef if not -e '/usr/sbin/rabbitmqctl';
	my $result = {};
	my $first = 1;
	for my $line (`/usr/sbin/rabbitmqctl list_queues -p "$arg_vhost"`)
	{
		if ($first)
		{
			$first = 0;
			next;
		}
		my ($name, $status) = $line =~ m/^([^\t]+)\t+([^\t]+)/;
		$result->{$name} = $status;
	}
	return $result;
}

sub queue_discovery
{
	my $queues = getQueues;
	return 0 if not defined $queues;
	my @names = keys %$queues;
	printDiscoveryHead;
	for (@names)
	{
		printDiscoveryItem {'NAME' => $_};
	}
	printDiscoveryEnd;
	return 1;
}

sub queue_status
{
	my $queues = getQueues;
	return 0 if not defined $queues;
	my @names = keys %$queues;
	for (@names)
	{
		if ($_ eq $arg_status)
		{
			say $queues->{$_};
			return 1;
		}
	}
	return 0;
}

if ($arg_type eq 'queue')
{
	exit (queue_discovery()? 0: 1) if $arg_discovery;
	exit (queue_status()? 0: 1) if $arg_status;
}
elsif ($arg_type eq 'vhost')
{

}

exit 2;
