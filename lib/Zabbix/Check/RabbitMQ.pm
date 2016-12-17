package Zabbix::Check::RabbitMQ;
=head1 NAME

Zabbix::Check::RabbitMQ - Zabbix check RabbitMQ service

=head1 VERSION

version 1.01

=head1 SYNOPSIS

Zabbix check RabbitMQ service

=cut
use strict;
use warnings;
no warnings qw(qw utf8);
use v5.14;
use utf8;

use Zabbix::Check;


BEGIN
{
	require Exporter;
	# set the version for version checking
	our $VERSION     = '1.01';
	# Inherit from Exporter to export functions and variables
	our @ISA         = qw(Exporter);
	# Functions and variables which are exported by default
	our @EXPORT      = qw(_vhost_discovery _queue_discovery _queue_status);
	# Functions and variables which can be optionally exported
	our @EXPORT_OK   = qw();
}


sub getVhosts
{
	return unless -x '/usr/sbin/rabbitmqctl';
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
		my ($name) = $line =~ /^(.*)/;
		$result->{$name} = { 'name' => $name };
	}
	return $result;
}

sub getQueues
{
	my ($vhost) = @_;
	return unless -x '/usr/sbin/rabbitmqctl';
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

sub _vhost_discovery
{
	my @items;
	my $vhosts = getVhosts();
	return unless $vhosts;
	for my $vhost (keys %$vhosts)
	{ 
		push @items, { vhost => $vhost };
	}
	return Zabbix::Check::printDiscovery(@items);
}

sub _queue_discovery
{
	my @items;
	my $vhosts = getVhosts();
	return unless $vhosts;
	for my $vhost (keys %$vhosts)
	{ 
		my $queues = getQueues($vhost);
		next unless $queues;
		for my $queue (keys %$queues)
		{
			push @items, { vhost => $vhost, queue => $queue };
		}
	}
	return Zabbix::Check::printDiscovery(@items);
}

sub _queue_status
{
	my ($vhost, $queue, $type) = @ARGV;
	return unless $vhost and $queue and $type and $type =~ /^ready|unacked|total$/;
	my $queues = getQueues($vhost);
	return unless defined $queues->{$queue};
	my $result = $queues->{$queue}->{$type};
	print $result;
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
