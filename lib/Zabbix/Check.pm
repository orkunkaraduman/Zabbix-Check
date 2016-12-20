package Zabbix::Check;
=head1 NAME

Zabbix::Check - Zabbix Agent system and service checks

=head1 VERSION

version 1.04

=head1 SYNOPSIS

Zabbix Agent system and service checks

=head3 zabbix_agentd.conf

UserParameter=cpan.zabbix.check.version,/usr/bin/perl -MZabbix::Check -e_version

=head2 Disk

Zabbix check for disk

=head3 zabbix_agentd.conf

	UserParameter=cpan.zabbix.check.disk.discovery,/usr/bin/perl -MZabbix::Check::Disk -e_discovery
	UserParameter=cpan.zabbix.check.disk.bps[*],/usr/bin/perl -MZabbix::Check::Disk -e_bps $1 $2
	UserParameter=cpan.zabbix.check.disk.iops[*],/usr/bin/perl -MZabbix::Check::Disk -e_iops $1 $2
	UserParameter=cpan.zabbix.check.disk.ioutil[*],/usr/bin/perl -MZabbix::Check::Disk -e_ioutil $1 $2

$1 I<Device name eg: sda, sdb1, dm-3, ...>

$2 I<Type: read|write|total>

=head2 Supervisor

Zabbix check for Supervisor service

=head3 zabbix_agentd.conf

	UserParameter=cpan.zabbix.check.supervisor.installed,/usr/bin/perl -MZabbix::Check::Supervisor -e_installed
	UserParameter=cpan.zabbix.check.supervisor.check,/usr/bin/perl -MZabbix::Check::Supervisor -e_check
	UserParameter=cpan.zabbix.check.supervisor.worker_discovery,/usr/bin/perl -MZabbix::Check::Supervisor -e_worker_discovery
	UserParameter=cpan.zabbix.check.supervisor.worker_status[*],/usr/bin/perl -MZabbix::Check::Supervisor -e_worker_status $1

B<worker_status $1>

$1 I<Worker name>

=head2 RabbitMQ

Zabbix check for RabbitMQ service

=head3 zabbix_agentd.conf

	UserParameter=cpan.zabbix.check.rabbitmq.installed,/usr/bin/perl -MZabbix::Check::RabbitMQ -e_installed
	UserParameter=cpan.zabbix.check.rabbitmq.check,/usr/bin/perl -MZabbix::Check::RabbitMQ -e_check
	UserParameter=cpan.zabbix.check.rabbitmq.vhost_discovery,/usr/bin/perl -MZabbix::Check::RabbitMQ -e_vhost_discovery
	UserParameter=cpan.zabbix.check.rabbitmq.queue_discovery,/usr/bin/perl -MZabbix::Check::RabbitMQ -e_queue_discovery
	UserParameter=cpan.zabbix.check.rabbitmq.queue_status[*],/usr/bin/perl -MZabbix::Check::RabbitMQ -e_queue_status $1 $2 $3

B<queue_status $1 $2 $3>

$1 I<Vhost name>

$2 I<Queue name>

$3 I<Type: ready|unacked|total>

=head2 Systemd

Zabbix check for Systemd services

=head3 zabbix_agentd.conf

	UserParameter=cpan.zabbix.check.systemd.installed,/usr/bin/perl -MZabbix::Check::Systemd -e_installed
	UserParameter=cpan.zabbix.check.systemd.check,/usr/bin/perl -MZabbix::Check::Systemd -e_check
	UserParameter=cpan.zabbix.check.systemd.service_discovery,/usr/bin/perl -MZabbix::Check::Systemd -e_service_discovery
	UserParameter=cpan.zabbix.check.systemd.service_status[*],/usr/bin/perl -MZabbix::Check::Systemd -e_service_status $1

B<service_status $1>

$1 I<Service name>

=head1 INSTALLATION

To install this module type the following

	perl Makefile.PL
	make
	make test
	make install

from CPAN

	cpan -i Zabbix::Check

=head1 DEPENDENCIES

This module requires these other modules and libraries:

=over

=item *

Switch

=item *

FindBin

=item *

Cwd

=item *

File::Basename

=item *

File::Slurp

=item *

JSON

=back

=cut
use strict;
use warnings;
no warnings qw(qw utf8);
use v5.14;
use utf8;
use Config;
use JSON;


BEGIN
{
	require Exporter;
	# set the version for version checking
	our $VERSION     = '1.04';
	# Inherit from Exporter to export functions and variables
	our @ISA         = qw(Exporter);
	# Functions and variables which are exported by default
	our @EXPORT      = qw(zbxEncode zbxDecode printDiscovery whereisBin _version);
	# Functions and variables which can be optionally exported
	our @EXPORT_OK   = qw();
}


our @zbxSpecials = (qw(\ ' " ` * ? [ ] { } ~ $ ! & ; ( ) < > | # @), "\n");


sub zbxEncode
{
	my $result = "";
	my ($str) = @_;
	return $result unless $str;
	for (my $i = 0; $i < length $str; $i++)
	{
		my $chr = substr $str, $i, 1;
		if (grep ($_ eq $chr, (@zbxSpecials, '%')))
		{
			$result .= uc sprintf("%%%x", ord($chr));
		} else
		{
			$result .= $chr;
		}
	}
	return $result;
}

sub zbxDecode
{
	my $result = "";
	my ($str) = @_;
	return $result unless $str;
	my ($i, $len) = (0, length $str);
	while ($i < $len)
	{
		my $chr = substr $str, $i, 1;
		if ($chr eq '%')
		{
			return $result if $len-$i-1 < 2;
			$result .= chr(hex(substr($str, $i+1, 2)));
			$i += 2;
		} else
		{
			$result .= $chr;
		}
		$i++;
	}
	return $result;
}

sub printDiscovery
{
	my @items = @_;
	my $discovery = {
		data => [
			map({
				my $item = $_; 
				my %newitem = map({
					my $key = $_;
					my $val = $item->{$key};
					my $newkey = zbxEncode($key);
					$newkey = uc("{#$newkey}");
					my $newval = zbxEncode($val);
					$newkey => $newval;
				} keys(%$item));
				\%newitem;
			} @items),
		],
	};
	my $result = to_json($discovery, {pretty => 1});
	print $result;
	return $result;
}

sub whereisBin
{
	my ($name) = @_;
	return grep(-x $_, map("$_/$name", split(":", "/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin")));
}

sub _version
{
	my $result = "";
	$result = $VERSION;
	return $result;
}


my $osname = $Config{osname};
die "OS '$osname' is not supported" unless $osname eq 'linux';

1;
__END__
=head1 REPOSITORY

B<GitHub> L<https://github.com/orkunkaraduman/Zabbix-Check>

B<CPAN> L<https://metacpan.org/release/Zabbix-Check>

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
