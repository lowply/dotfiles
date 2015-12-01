#/usr/bin/env bash

#
# ------------------------------
# S3 Backup Script
# ------------------------------
#
# version : 0.9 (2015/06/09 lowply@gmail.com)
# - minor updates
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

# for multibyte filenames
export LANG=en_US.UTF-8
export PATH=${HOME}/.pyenv/shims:${PATH}

WD="${HOME}/s3backup"
CONF="${WD}/backup.conf"
LOGFILE="${WD}/log/$(date +%y%m%d_%H%M%S).log"

logger(){
	echo "$(date): [Info] ${1}" | tee -a ${LOGFILE}
}

error(){
	echo "$(date): [Error] ${1}" | tee -a ${LOGFILE} 1>&2 
	exit 1
}

main(){
	# check aws command
	type aws > /dev/null 2>&1 || error "aws cli is not installed"

	# check aws config file
	[ -f ${HOME}/.aws/config ] || error "~/.aws/config is not found"

	# create workingdir and sub directries
	if [ ! -d ${WD} ]; then
 		mkdir ${WD}
		cd ${WD}
		mkdir log
		mkdir excludes
		cat <<- EOL > ${CONF}
			# Backup enabled
			ENABLED="true" # true or false
			BACKET="" # backet name
			BACKUPDIR="" # backup dir name in the backet
			NODE="" # host name or IP address
		EOL
		chmod 600 ${CONF}
		error "${CONF} created, please update it"
	else
		# check conf file permission
		[ "$(stat --format='%a' ${CONF})" == "600" ] || error "permission of ${CONF} is not 600"

		# read conf file
		. ${CONF}

		# check conf has enough information
		[ -z "${ENABLED}" -o -z "${BACKET}" -o -z "${BACKUPDIR}" -o -z "${NODE}" ] && error "Not enough information in ${CONF}"
	fi

	# options
	if [ "${1}" == "d" ]; then
		OPTS="--profile default --no-follow-symlinks --delete --storage-class REDUCED_REDUNDANCY --dryrun"
	else
		OPTS="--profile default --no-follow-symlinks --delete --storage-class REDUCED_REDUNDANCY"
	fi

	function syncdir(){
		TARGET=${1}
		command="aws s3 sync ${OPTS} /${TARGET}/ s3://${BACKET}/${BACKUPDIR}/${NODE}/${TARGET}/"
		
		if [ -f ${WD}/excludes/${TARGET} ]; then
			while read exclude
			do
				command="${command} --exclude \"${exclude}\""
			done < ${WD}/excludes/${TARGET}
		fi
		
		logger "${command}"
		eval "${command}" | tee -a ${LOGFILE}
		
		logger "------ /${TARGET}/"
	}

	#
	# Action
	#

	logger "------ Backup started at $(date +%c)"

	if [ ${ENABLED} == "true" ]; then
		syncdir "root"
		syncdir "etc"
		syncdir "home"
	else
		echo "s3backup is disabled."
	fi

	logger "------ Backup completed at $(date +%c)"
}

main "$@"
