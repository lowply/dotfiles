#!/bin/bash

# ------------------------------
# Backup script for MySQL
# ------------------------------

. $(dirname $0)/lib.sh

DATE=$(date +%y%m%d.%H%M%S)
CONF="${HOME}/.mysql_access"

# check if this host is linux
check_os "linux"

# check if mysql is installed
has mysql

# check if mysqld is running
[ ! -z "$(/sbin/pidof mysqld)" ] || error "mysql is not running"

# if conf file does not exist, create it
if [ ! -f ${CONF} ]; then
	cat <<- EOL > ${CONF}
		DBUSER=""
		DBPASS=""
		PERIOD="14"
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
	[ -z "${DBUSER}" -o -z "${DBPASS}" -o -z "${PERIOD}" -o -z "${ENC}" -o -z "${BACKUPDIR}" ] && error "Not enough information in ${CONF}"
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
	logger "mysqldump --events --default-character-set=${ENC} --opt -c -u${DBUSER} -p\$DBPASS ${DBNAME} > ./${DBNAME}.sql"
	mysqldump ${EVENTS} --default-character-set=${ENC} --opt -c -u${DBUSER} -p${DBPASS} ${DBNAME} > ./${DBNAME}.sql
	gzip -f ./${DBNAME}.sql
done

# delete old dir
logger "Deleting old backups..."
find ${BACKUPDIR}/ -type d -mtime +${PERIOD} | xargs rm -rf

logger "Finished backup..."
