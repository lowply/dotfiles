#!/bin/sh

#
# version : 1.80 (2015/06/09 sho@fixture.jp)
# - Minor updates for conf file handling
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

DATE=$(date +%y%m%d.%H%M%S)
CONF="${HOME}/.mysql_access"
LOGFILE="/var/log/backup_mysql.log"

logger(){
	echo "$(date): [Info] ${1}" | tee -a ${LOGFILE}
}

error(){
	echo "$(date): [Error] ${1}" | tee -a ${LOGFILE} 1>&2 
	exit 1
}

main(){
	# check if this host is linux
	echo ${OSTYPE} | grep "linux" > /dev/null || error "Not a Linux OS"
	
	# check if mysql is installed
	type mysql > /dev/null 2>&1 || error "mysql is not installed"

	# check if mysqld is running
	[ ! -z "$(/sbin/pidof mysqld)" ] || error "mysql is not running"

	# if conf file does not exist, create it
	if [ ! -f ${CONF} ]; then
		cat <<- EOL > ${CONF}
			DBUSER=""
			DBPASS=""
			TERM="14"
			ENC="binary"
			BACKUPDIR="/home/backup/mysql"
		EOL
		chmod 600 ${CONF}
		error "${CONF} created, please update it"
	else
		# check if conf file exists with permission 600
		[ "$(stat --format='%a' ${CONF})" == "600" ] || error "Permission of ${CONF} is not 600"

		# load conf
		. ${CONF}

		# check conf file has enough information
		[ -z "${DBUSER}" -o -z "${DBPASS}" -o -z "${TERM}" -o -z "${ENC}" -o -z "${BACKUPDIR}" ] && error "Not enough information in ${CONF}"
	fi

	# create target DB list
	LIST=$(mysql -u${DBUSER} -p${DBPASS} -N -e 'show databases' | grep -v '_schema')
	
	# validate username and password
	[ $? -ne 0 ] && error "Can't connect to mysql server, username or password is invalid"

	# create backup dir if it doesn't exist
	[ -d ${BACKUPDIR} ] || mkdir -p ${BACKUPDIR}

	# change dir
	mkdir -p ${BACKUPDIR}/${DATE}
	cd ${BACKUPDIR}/${DATE}

	if mysql --version | grep "Distrib 5.0" > /dev/null ; then
		# for mysql 5.0.x, mostly Cent OS 5.x
		EVENTS=""
	else
		EVENTS="--events"
	fi

	logger "Starting backup..."
	# get backup and gzip
	for DBNAME in ${LIST}
	do
		logger "mysqldump --events --default-character-set=${ENC} --opt -c -u${DBUSER} -p${DBPASS} ${DBNAME} > ./${DBNAME}.sql"
		mysqldump ${EVENTS} --default-character-set=${ENC} --opt -c -u${DBUSER} -p${DBPASS} ${DBNAME} > ./${DBNAME}.sql
		gzip -f ./${DBNAME}.sql
	done

	# delete old dir
	logger "Deleting old backups..."
	find ${BACKUPDIR}/ -type d -mtime +${TERM} | xargs rm -rf

	logger "Finished backup..."
}

main "$@"
