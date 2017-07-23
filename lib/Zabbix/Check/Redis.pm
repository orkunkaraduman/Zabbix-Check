package Zabbix::Check::Redis;
=head1 NAME

Zabbix::Check::Redis - Zabbix check for Redis service

=head1 VERSION

version 1.11

=head1 SYNOPSIS

Zabbix check for Redis service

=cut
use strict;
use warnings;
use v5.10.1;
use Lazy::Utils;

use Zabbix::Check;


BEGIN
{
	require Exporter;
	our $VERSION     = '1.11';
	our @ISA         = qw(Exporter);
	our @EXPORT      = qw(_installed _running _info);
	our @EXPORT_OK   = qw();
}


our ($redis_server) = whereis('redis-server');
our ($redis_cli) = whereis('redis-cli');


sub get_info
{
	return unless $redis_cli;
	my $result = file_cache("all", 30, sub
	{
		my $result = { 'epoch' => time() };
		my $topic; 
		for (`$redis_cli info 2>/dev/null`)
		{
			chomp;
			if (/^#(.*)/)
			{
				$topic = trim($1);
				$result->{$topic} = {} unless defined($result->{$topic});
				next;
			}
			my ($key, $val) = split(":", $_, 2);
			next unless defined($topic) and defined($key) and defined($val);
			$key = trim($key);
			$val = trim($val);
			$result->{$topic}->{$key} = $val;
		}
		return $result;
	});
	return $result;
}

sub _installed
{
	my $result = $redis_server? 1: 0;
	print $result;
	return $result;
}

sub _running
{
	my $result = 2;
	if ($supervisorctl)
	{
		system "pgrep -f '$redis_server' >/dev/null 2>&1";
		$result = ($? == 0)? 1: 0;
	}
	print $result;
	return $result;
}

sub _info
{
	my ($topic, $key) = map(zbx_decode($_), @ARGV);
	return "" unless $topic and $key;
	my $result = "";
	my $info = get_info();
	$result = $info->{$topic}->{$key} if defined($info->{$topic}->{$key});
	print $result;
	return $result;
}


1;
__END__
=head1 REPOSITORY

B<GitHub> L<https://github.com/orkunkaraduman/Zabbix-Check>

B<CPAN> L<https://metacpan.org/release/Zabbix-Check>

=head1 AUTHOR

Orkun Karaduman (ORKUN) <orkun@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2017  Orkun Karaduman <orkunkaraduman@gmail.com>

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
