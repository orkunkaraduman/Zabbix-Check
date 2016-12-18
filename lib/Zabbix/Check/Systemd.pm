package Zabbix::Check::Systemd;
=head1 NAME

Zabbix::Check::Systemd - Zabbix check for Systemd service

=head1 VERSION

version 1.02

=head1 SYNOPSIS

Zabbix check for Systemd service

=head3 zabbix_agentd.conf

	UserParameter=cpan.zabbix.check.systemd.installed,/usr/bin/perl -MZabbix::Check::Systemd -e_installed
	UserParameter=cpan.zabbix.check.systemd.check,/usr/bin/perl -MZabbix::Check::Systemd -e_check
	UserParameter=cpan.zabbix.check.systemd.service_discovery,/usr/bin/perl -MZabbix::Check::Systemd -e_service_discovery
	UserParameter=cpan.zabbix.check.systemd.service_status[*],/usr/bin/perl -MZabbix::Check::Systemd -e_service_status $1

B<service_status $1>

$1 I<Service name>

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
	our @EXPORT      = qw(_installed _check _service_discovery _service_status);
	# Functions and variables which can be optionally exported
	our @EXPORT_OK   = qw();
}


our ($systemctl) = whereisBin('systemctl');


sub getUnits
{
	return unless defined($systemctl) and -x $systemctl;
	my ($type, $stateRgx) = @_;
	my $result = {};
	my $first = 1;
	for (`$systemctl list-unit-files`)
	{
		chomp;
		if ($first)
		{
			$first = 0;
			next;
		}
		last unless s/^\s+|\s+$//gr;
		my ($unit, $state) = /^(\S+)\s+(\S+)/;
		my $unitInfo = {
			unit => $unit,
			state => $state,
		};
		($unitInfo->{name}, $unitInfo->{type}) = $unit =~ /^([^\.]*)\.(.*)/;
		$result->{$unit} = $unitInfo if (not $type or $type eq $unitInfo->{type}) and (not $stateRgx or $state =~ /$stateRgx/);
	}
	return $result;
}

sub _installed
{
	my $result = (defined($systemctl) and -x $systemctl)? 1: 0;
	print $result;
	return $result;
}

sub _check
{
	my $result = 2;
	if (defined($systemctl) and -x $systemctl)
	{
		system "$systemctl is-system-running >/dev/null 2>&1";
		$result = ($? == 0)? 1: 0;
	}
	print $result;
	return $result;
}

sub _service_discovery
{
	return unless defined($systemctl) and -x $systemctl;
	my ($stateRgx) = map(zbxDecode($_), @ARGV);
	$stateRgx = '^enabled' unless defined $stateRgx;
	my $units = getUnits('service', $stateRgx);
	return unless $units;
	my @items = map($units->{$_}, keys %$units);
	return printDiscovery(@items);
}

sub _service_status
{
	return unless defined($systemctl) and -x $systemctl;
	my ($name) = map(zbxDecode($_), @ARGV);
	return unless $name;
	my $result = `$systemctl is-active \"\Q$name\E.service\" 2>/dev/null`;
	return unless defined $result;
	chomp $result;
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
