package Zabbix::Check::Supervisor;
=head1 NAME

Zabbix::Check::Supervisor - Zabbix check for Supervisor service

=head1 VERSION

version 1.02

=head1 SYNOPSIS

Zabbix check for Supervisor service

=head3 zabbix_agentd.conf

	UserParameter=cpan.zabbix.check.supervisor.installed,/usr/bin/perl -MZabbix::Check::Supervisor -e_installed
	UserParameter=cpan.zabbix.check.supervisor.check,/usr/bin/perl -MZabbix::Check::Supervisor -e_check
	UserParameter=cpan.zabbix.check.supervisor.worker_discovery,/usr/bin/perl -MZabbix::Check::Supervisor -e_worker_discovery
	UserParameter=cpan.zabbix.check.supervisor.worker_status[*],/usr/bin/perl -MZabbix::Check::Supervisor -e_worker_status $1

B<worker_status $1>

$1 I<Worker name>

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
	our $VERSION     = '1.02';
	# Inherit from Exporter to export functions and variables
	our @ISA         = qw(Exporter);
	# Functions and variables which are exported by default
	our @EXPORT      = qw(_installed _check _worker_discovery _worker_status);
	# Functions and variables which can be optionally exported
	our @EXPORT_OK   = qw();
}


our ($supervisorctl) = whereisBin('supervisorctl');
our ($supervisord) = whereisBin('supervisord');


sub getStatuses
{
	return unless defined($supervisorctl) and -x $supervisorctl;
	my $result = {};
	for (`$supervisorctl status 2>/dev/null`)
	{
		chomp;
		my ($name, $status) = /^(\S+)\s+(\S+)\s*/;
		$result->{$name} = $status;
	}
	return $result;
}

sub _installed
{
	my $result = (defined($supervisorctl) and -x $supervisorctl)? 1: 0;
	print $result;
	return $result;
}

sub _check
{
	return unless defined($supervisorctl) and -x $supervisorctl;
	system "pgrep -f '/usr/bin/python $supervisord' >/dev/null 2>&1";
	my $result = ($? == 0)? 1: 0;
	print $result;
	return $result;
}

sub _worker_discovery
{
	my $statuses = getStatuses();
	return unless $statuses;
	my @items = map({ name => $_}, keys %$statuses);
	return printDiscovery(@items);
}

sub _worker_status
{
	my ($name) = map(zbxDecode($_), @ARGV);
	return unless $name;
	my $statuses = getStatuses();
	return unless defined $statuses->{$name};
	my $result = $statuses->{$name};
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
