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
our $arg_queue;
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
	elsif ($arg =~ /^\-q|\-\-queue$/)
	{
		$arg_queue = shift;
	}
	else
	{
		die "Bad input argument $arg";
	}
}
die "type argument is missed" if not defined $arg_type;

sub getQueues
{
	my ($vhost) = @_;
	return undef if not -e '/usr/sbin/rabbitmqctl';
	my $result = {};
	my $first = 1;
	for my $line (`/usr/sbin/rabbitmqctl list_queues -p "$vhost" name messages_ready messages_unacknowledged messages`)
	{
		chomp $line;
		if ($first)
		{
			$first = 0;
			next;
		}
		my ($name, $ready, $unacked, $total) = $line =~ m/^([^\t]+)\t+([^\t]+)\t+([^\t]+)\t+([^\t]+)\t*/;
		$result->{$name} = {'ready' => $ready, 'unacked' => $unacked, 'total' => $total};
	}
	return $result;
}

sub getVhosts
{
	return undef if not -e '/usr/sbin/rabbitmqctl';
	my $result = {};
	my $first = 1;
	for my $line (`/usr/sbin/rabbitmqctl list_vhosts`)
	{
		chomp $line;
		if ($first)
		{
			$first = 0;
			next;
		}
		my ($name) = $line =~ m/^(.*)/;
		$result->{$name} = $name;
	}
	return $result;
}

sub queue_discovery
{
	my $vhosts = getVhosts;
	return 0 if not defined $vhosts;
	printDiscoveryHead;
	for my $vhost (keys %$vhosts)
	{ 
		my $queues = getQueues $vhost;
		next if not defined $queues;
		for my $queue (keys %$queues)
		{
			printDiscoveryItem {'VHOST' => $vhost, 'QUEUE' => $queue};
		}
	}
	printDiscoveryEnd;
	return 1;
}

sub queue_status
{
	my $queues = getQueues $arg_vhost;
	return 0 if not defined $queues;
	my @names = keys %$queues;
	for (@names)
	{
		if ($_ eq $arg_queue)
		{
			my $val = $queues->{$_};
			if (defined $val->{$arg_status})
			{
				say $val->{$arg_status};
				return 1;
			} else
			{
				return 0;
			}
		}
	}
	return 0;
}

sub vhost_discovery
{
	my $vhosts = getVhosts;
	return 0 if not defined $vhosts;
	printDiscoveryHead;
	for my $vhost (keys %$vhosts)
	{
		printDiscoveryItem {'VHOST' => $vhost};
	}
	printDiscoveryEnd;
	return 1;
}

if ($arg_type eq 'queue')
{
	exit (queue_discovery()? 0: 1) if $arg_discovery;
	die "vhost argument is missed" if not defined $arg_vhost;
	die "queue argument is missed" if not defined $arg_queue;
	exit (queue_status()? 0: 1) if $arg_status;
}
elsif ($arg_type eq 'vhost')
{
	exit (vhost_discovery()? 0: 1) if $arg_discovery;
}

die "Invalid argument(s)";
