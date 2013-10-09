Author: Shane Jordan (shane@linuxgangster.org) - Please send bugs, bugfixes or enhancements.

Requirements: linux iostat utility. 

Installtion:
Copy check_tps.sh to your nagios plugin directory

Install a crontab for checking the device you want to gather stats for. Here is a example of one I setup for sda to run every minute:
* * * * * /usr/bin/iostat -d /dev/sda -t 58 2 | grep -n sda | grep 9:sda | awk -F" " '{print $2;}' > /tmp/tps.tmp && mv /tmp/tps.tmp /tmp/tps

Be sure to replace all instances of sda with the device you are check. You can also change it to run every 5 minutes instead of 1 minute. Here is a cron example running every 5 minutes checking sdb:
*/5 * * * * /usr/bin/iostat -d /dev/sdb -t 298 2 | grep -n sdb | grep 9:sdb | awk -F" " '{print $2;}' > /tmp/tps.tmp && mv /tmp/tps.tmp /tmp/tps

I always set the iostat utility to gather for 2-5 seconds shorter then the cron.
