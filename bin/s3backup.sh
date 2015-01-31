#/usr/bin/env bash

#
# ------------------------------
# S3 Backup Script
# ------------------------------
#
# version : 0.8 (2014/12/08 lowply@gmail.com)
# - working dir name change
# - separate config file
#
# version : 0.7 (2014/10/22 lowply@gmail.com)
# - exclude options are taken out of the script
# - change working directory to /root/backup
# - no more virtualenv, python 2.6 compatible
#
# version : 0.6 (2014/06/05 lowply@gmail.com)
# - big change
# - start using aws sync
#
# version : 0.5 (2014/04/08 lowply@gmail.com)
# - changed exclude file handling
# - tar doesn't show "Removing leading '/' from member names" warning anymore
#
# version : 0.4 (2014/03/26 lowply@gmail.com)
# - changed location of temporary tar archive to /tmp and not erase them until next backup
#
# version : 0.3 (2014/01/26 lowply@gmail.com)
# - added generation management (delete directory older than 7 days)
# - added directory check (if backup dir of the day exists, stop backup)
# - changed directory name (deleted HOUR in dir name)
#
# version : 0.2 (2014/01/13 lowply@gmail.com)
# - added pigz option
#
# version : 0.1 (2014/01/10 lowply@gmail.com)
# - First edition
#
# Preparation : aws configure, /backup/[ipaddress] folder in S3 bucket
#
# ------------------------------
#

main(){
	# for multibyte filenames
	export LANG=en_US.UTF-8

	WD="$HOME/s3backup"
	CONF="${WD}/backup.conf"
	CONFFORMAT="
----------
# Backup enabled
ENABLED=true|false

# Bucket name
BACKET=\"\"

# Backup dir name
BACKUPDIR=\"\"

# Node name
NODE=\"\"
----------
	"

	# check aws command
	type aws > /dev/null 2>&1 || { echo "aws cli is not installed."; exit 1; }

	# check aws config file
	[ -f $HOME/.aws/config ] || { echo "~/.aws/config is not found"; exit 1; }

	# create workingdir and sub directries
	[ -d ${WD} ] || { mkdir ${WD}; cd ${WD}; mkdir log; mkdir excludes; touch backup.conf; chmod 600 backup.conf; }

	# check conf file permission
	[ "$(stat --format='%a' ${CONF})" == "600" ] || { echo "permission of ${CONF} is not 600."; exit 1; }

	# read conf file
	. ${CONF}

	# check conf has enough information
	[ -z "${ENABLED}" -o -z "${BACKET}" -o -z "${BACKUPDIR}" -o -z "${NODE}" ] && { echo -e "Not enough information on ${CONF}. Conf should have following variables:\n${CONFFORMAT}"; exit 1; }

	# options
	if [ "${1}" == "d" ]; then
		OPTS="--profile default --no-follow-symlinks --delete --storage-class REDUCED_REDUNDANCY --dryrun"
	else
		OPTS="--profile default --no-follow-symlinks --delete --storage-class REDUCED_REDUNDANCY"
	fi

	# log
	LOGFILE="${WD}/log/$(date +%y%m%d_%H%M%S).log"

	function syncdir(){
		TARGET=${1}
		command="aws s3 sync ${OPTS} /${TARGET}/ s3://${BACKET}/${BACKUPDIR}/${NODE}/${TARGET}/"
		
		if [ -f ${WD}/excludes/${TARGET} ]; then
			while read exclude
			do
				command="${command} --exclude \"${exclude}\""
			done < ${WD}/excludes/${TARGET}
		fi
		
		echo "${command}" | tee -a ${LOGFILE}
		eval "${command}" | tee -a ${LOGFILE}
		
		echo "------ /${TARGET}/" | tee -a ${LOGFILE}
		echo -e "\n\n" | tee -a ${LOGFILE}
	}

	#
	# Action
	#

	echo "------ Backup started at $(date +%c)" > ${LOGFILE}

	if [ ${ENABLED} == "true" ]; then
		syncdir "root"
		syncdir "etc"
		syncdir "home"
	else
		echo "s3backup is disabled."
	fi

	echo "------ Backup completed at $(date +%c)" >> ${LOGFILE}
}

main "$@"
