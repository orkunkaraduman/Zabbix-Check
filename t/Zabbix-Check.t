use strict;
use warnings;

use Test::More tests => 2;


BEGIN
{
	use_ok('Zabbix::Check');
	use_ok('Zabbix::Check::Disk');
}
