#!/bin/sh

#
# version : 1.50 (2014/09/02 sho@fixture.jp)
# - remove _DBPASS
#
# version : 1.40 (2012/03/08 sho@fixture.jp)
# - Bug Fix : User/Pass added to for sentence
# 
# version : 1.30 (2012/03/07 sho@fixture.jp)
# - Bug Fix
# 
# version : 1.20 (2012/02/28 sho@fixture.jp)
# - Changed : Using mysql command to get database list instead of ls command
#             so that it doesn't depends on where the datadir is.
# 
# version : 1.10 (2011/12/27 sho@fixture.jp) 
# - Revised whole script.
# 
# version : 1.00
# - First edition.
# 

echo ${OSTYPE} | grep "linux" > /dev/null || { echo "Not a Linux OS"; exit 1; }
[ -f $HOME/.mysql_access ] || { echo ""; exit 1; }

. $HOME/.mysql_access

# you can change these vars for your server.
TERM=14
ENC=binary
BACKUPDIR=/home/backup/mysql

DATE=$(date +%y%m%d)
PID=$(/sbin/pidof mysqld)

# check mysql pass is set
[ -z "${DBPASS}" ] && { echo "DBPASS is not set, aborting."; exit 1; }

# check mysqld is running or not
[ -z "${PID}" ] && { echo "mysql is not running"; exit 1; }

# make dir if it doesn't exist
[ -d ${BACKUPDIR} ] || mkdir -p ${BACKUPDIR}
[ -d ${BACKUPDIR}/${DATE} ] || mkdir -p ${BACKUPDIR}/${DATE}

# change dir
cd ${BACKUPDIR}/${DATE}

# get backup and gzip
for DBNAME in $(mysql -u${DBUSER} -p${DBPASS} -N -e 'show databases' | grep -v '_schema')
do
	mysqldump --events --default-character-set=${ENC} --opt -c -u${DBUSER} -p${DBPASS} ${DBNAME} > ./${DBNAME}.sql
	gzip -f ./${DBNAME}.sql
done

# delete old dir
find ${BACKUPDIR}/ -type d -mtime +${TERM} | xargs rm -rf
