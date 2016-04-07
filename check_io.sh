#!/bin/bash
# Script to check IOPS for Zabbix
# Written by: Orkun Karaduman (orkunkaraduman@gmail.com)
# Requirements: iostats
# Version 1.0
#

USAGE="`basename $0` {[-t|--type]<type>} {[-d|--dev]<device>}"

while [[ $# -gt 0 ]]
  do
        case "$1" in
               -d|--dev)
               shift
               dev=$1
        ;;
               -t|--type)
               shift
               typ=$1
        ;;
        esac
        shift
  done

if [ -z "$typ" ]
then
    typ="wait"
fi

case "$typ" in
       tps)
       if [ -z "$dev" ]
       then
           echo ""
           echo "Wrong Syntax: `basename $0` $*"
           echo ""
           echo "Usage: $USAGE"
           echo ""
           exit 1
       fi
       val=`/usr/bin/iostat -d /dev/$dev -t 5 2 | grep -n $dev | grep 9:$dev | awk -F " " '{print $2;}'`
;;
       util)
       if [ -z "$dev" ]
       then
           echo ""
           echo "Wrong Syntax: `basename $0` $*"
           echo ""
           echo "Usage: $USAGE"
           echo ""
           exit 1
       fi
       val=`/usr/bin/iostat -d /dev/$dev -t 5 2 -x | grep -n $dev | grep 9:$dev | awk -F " " '{print $14;}'`
;;
       wait|*)
       val=`/usr/bin/iostat -c 5 2 | grep -n "" | grep "7:"  | awk -F " " '{print $5;}'`
;;
esac
val=`sed 's/,/./g' <<< $val`

echo $val
exit 0
