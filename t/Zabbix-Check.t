use strict;
use warnings;

use Test::More tests => 4;


BEGIN
{
	use_ok('Zabbix::Check');
	use_ok('Zabbix::Check::Disk');
	use_ok('Zabbix::Check::Supervisor');
	use_ok('Zabbix::Check::RabbitMQ');
}
