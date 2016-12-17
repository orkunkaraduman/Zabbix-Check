package Zabbix::Check::Supervisor;
=head1 NAME

Zabbix::Check::Supervisor - Zabbix check supervisord service

=head1 VERSION

version 1.01

=head1 SYNOPSIS

Zabbix check supervisord service

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
	our @EXPORT      = qw();
	# Functions and variables which can be optionally exported
	our @EXPORT_OK   = qw();
}


sub getStatuses
{
	return unless -x '/usr/bin/supervisorctl';
	my $result = {};
	for (`/usr/bin/supervisorctl status`)
	{
		chomp;
		my ($name, $status) = /^(\S+)\s+(\S+)\s*/;
		$result->{$name} = $status;
	}
	return $result;
}

sub discovery
{
	my $statuses = getStatuses();
	return unless $statuses;
	my @items = map({ name => $_}, keys %$statuses);
	return Zabbix::Check::printDiscovery(@items);
}

sub check
{
	return 0 unless -x '/usr/bin/supervisorctl';
	system 'pgrep -f "/usr/bin/python /usr/bin/supervisord" >/dev/null 2>&1';
	my $result = ($? == 0)? 1: 0;
	print $result;
	return $result;
}

sub status
{
	my ($name) = @ARGV;
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
