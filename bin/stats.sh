#!/bin/sh

# -------------------------------------
# version : 1.00
# - First edition.
# -------------------------------------

echo ${OSTYPE} | grep "linux" || { echo "Not a Linux OS"; exit 1; }

#
# create dir if not exsits
#

if [ ! -d "/root/stats" ]
then
  mkdir /root/stats
fi

#
# rm old stats logs
#

find /root/stats/ -type f -mtime +30 -print0 | xargs -0 rm -f

#
# process
#

DATE=`date +%y%m%d-%H%M`

CMD[0]='uptime'
CMD[1]='free -m'
CMD[2]='df -h'
CMD[3]='netstat -tanp'
CMD[4]='ps auxwwww | grep -v "\[.*\]"'

echo "$DATE" > /root/stats/$DATE

for x in "${CMD[@]}"
do
  echo -e "\n\n-------------------\n[ $x ]\n-------------------\n\n" >> /root/stats/$DATE
  eval $x >> /root/stats/$DATE
done
