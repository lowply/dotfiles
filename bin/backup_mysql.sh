#!/bin/sh

#
# version : 1.70 (2014/12/10 sho@fixture.jp)
# - Enhance error checks
#
# version : 1.60 (2014/12/05 sho@fixture.jp)
# - Rename to backup_mysql
# - Date is now date.time format
# - Separate mysql access information to ~/.mysql_access
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

main(){
	TERM=14
	ENC=binary
	BACKUPDIR=/home/backup/mysql
	DATE=$(date +%y%m%d.%H%M%S)
	CONF="${HOME}/.mysql_access"
	CONFFORMAT="
	----------
	DBUSER=\"dbuser\"
	DBPASS=\"dbpass\"
	----------
	"

	# check if this host is linux
	echo ${OSTYPE} | grep "linux" > /dev/null || { echo "Not a Linux OS"; exit 1; }

	# check mysqld is running or not
	[ ! -z "$(/sbin/pidof mysqld)" ] || { echo "mysql is not running"; exit 1; }

	# if conf file exists
	[ -f ${CONF} ] || { echo "${CONF} could not be found. Conf file should include following variables:\n${CONFFORMAT}"; exit 1; }

	# if conf file exists with permission 600, load it
	[ "$(stat --format='%a' ${CONF})" == "600" ] && . ${CONF} || { echo "Permission of ${CONF} is not 600."; exit 1; }

	# check conf file has enough information
	[ -z "${DBUSER}" -o -z "${DBPASS}" ] && { echo "Not enough information on ${CONF}. Conf should have following variables:\n${CONFFORMAT}"; exit 1; }

	# make dir if it doesn't exist
	[ -d ${BACKUPDIR} ] || mkdir -p ${BACKUPDIR}

	# change dir
	mkdir -p ${BACKUPDIR}/${DATE}
	cd ${BACKUPDIR}/${DATE}

	# get backup and gzip
	for DBNAME in $(mysql -u${DBUSER} -p${DBPASS} -N -e 'show databases' | grep -v 'information_schema')
	do
		echo "mysqldump --events --default-character-set=${ENC} --opt -c -u${DBUSER} -p${DBPASS} ${DBNAME} > ./${DBNAME}.sql"
		mysqldump --events --default-character-set=${ENC} --opt -c -u${DBUSER} -p${DBPASS} ${DBNAME} > ./${DBNAME}.sql
		gzip -f ./${DBNAME}.sql
	done

	# delete old dir
	find ${BACKUPDIR}/ -type d -mtime +${TERM} | xargs rm -rf
}

main "$@"
