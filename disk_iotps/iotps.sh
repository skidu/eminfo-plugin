#!/bin/bash
# Script to check TPS (aka IOPS)
# Written by: Shane Jordan (shane@linuxgangster.org)
# Requirements: iostats and a cron entry (cron entry info in readme)
# Version 1.0
#
USAGE="`basename $0` [-w|--warning]<tps warning> [-c|--critical]<tps critical>"
THRESHOLD_USAGE="CRITICAL threshold must be greater than WARNING: `basename $0` $*"
critical=""
warning=""
if [[ $# -lt 4 ]]
then
	echo ""
	echo "Wrong Syntax: `basename $0` $*"
	echo ""
	echo "Usage: $USAGE"
	echo ""
	exit 0
fi
while [[ $# -gt 0 ]]
  do
        case "$1" in
               -w|--warning)
               shift
               warning=$1
        ;;
               -c|--critical)
               shift
               critical=$1
        ;;
        esac
        shift
  done
if [[ $warning -eq $critical || $warning -gt $critical ]]
then
	echo ""
	echo "$THRESHOLD_USAGE"
	echo ""
        echo "Usage: $USAGE"
	echo ""
        exit 0
fi

#Read the tps value
tps=`cat /tmp/tps`

if [ $(bc <<< "$tps >= $critical") -ne 0 ];
	then
		echo "CRITICAL: Transactions Per Second = $tps | tps=$tps;$warning;$critical"
		exit 2
fi
if [ $(bc <<< "$tps >= $warning") -ne 0 ];
        then
                echo "WARNING:  Transactions Per Second = $tps | tps=$tps;$warning;$critical"
                exit 1
fi
if [ $(bc <<< "$tps <= $warning") -ne 0 ];
        then
                echo "OK:  Transactions Per Second = $tps | tps=$tps;$warning;$critical"
                exit 0
fi

