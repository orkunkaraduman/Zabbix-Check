# NAME

Zabbix::Check - Zabbix checks

# VERSION

version 1.01

# SYNOPSIS

Zabbix checks

# USAGE

## Disk

### zabbix\_agentd.conf

$1 _Device name eg: sda, sdb1, dm-3, ..._

$2 _Type: read or write or total_

## Supervisor

### zabbix\_agentd.conf

`UserParameter=cpan.zabbix.check.supervisor.installed,/usr/bin/perl -MZabbix::Check::Supervisor -e_installed`

`UserParameter=cpan.zabbix.check.supervisor.check,/usr/bin/perl -MZabbix::Check::Supervisor -e_check`

`UserParameter=cpan.zabbix.check.supervisor.worker_discovery,/usr/bin/perl -MZabbix::Check::Supervisor -e_worker_discovery`

`UserParameter=cpan.zabbix.check.supervisor.worker_status[*],/usr/bin/perl -MZabbix::Check::Supervisor -e_worker_status $1`

**worker\_status**

$1 _Worker name_

## RabbitMQ

### zabbix\_agentd.conf

`UserParameter=cpan.zabbix.check.rabbitmq.installed,/usr/bin/perl -MZabbix::Check::RabbitMQ -e_installed`

`UserParameter=cpan.zabbix.check.rabbitmq.check,/usr/bin/perl -MZabbix::Check::RabbitMQ -e_check`

`UserParameter=cpan.zabbix.check.rabbitmq.vhost_discovery,/usr/bin/perl -MZabbix::Check::RabbitMQ -e_vhost_discovery`

`UserParameter=cpan.zabbix.check.rabbitmq.queue_discovery,/usr/bin/perl -MZabbix::Check::RabbitMQ -e_queue_discovery`

`UserParameter=cpan.zabbix.check.rabbitmq.queue_status[*],/usr/bin/perl -MZabbix::Check::RabbitMQ -e_queue_status $1 $2 $3`

**queue\_status**

$1 _Queue name_

# INSTALLATION

To install this module type the following

        perl Makefile.PL
        make
        make test
        make install

from CPAN

        cpan -i Zabbix::Check

# DEPENDENCIES

This module requires these other modules and libraries:

- Switch
- FindBin
- Cwd
- File::Basename
- File::Slurp
- JSON

# AUTHOR

Orkun Karaduman &lt;orkunkaraduman@gmail.com&gt;

# COPYRIGHT AND LICENSE

Copyright (C) 2016  Orkun Karaduman &lt;orkunkaraduman@gmail.com&gt;

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see &lt;http://www.gnu.org/licenses/&gt;.
