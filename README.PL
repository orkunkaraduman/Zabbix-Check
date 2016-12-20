use strict;
use warnings;


system('pod2markdown --html-encode-chars 1 lib/Zabbix/Check.pm > README.md');
system('pod2text lib/Zabbix/Check.pm > README');
system('git ls-files | grep -v "^\.gitignore" > MANIFEST');
