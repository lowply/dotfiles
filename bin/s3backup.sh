#/bin/bash

# ------------------------------
# Preparation :
# aws configure, /backup/[ipaddress] folder in S3 bucket
# ------------------------------

. $(dirname $0)/lib.sh

# for multibyte filenames
export LANG=en_US.UTF-8
export PATH=${HOME}/.pyenv/shims:${PATH}

WD="${HOME}/s3backup"
CONF="${WD}/backup.conf"

# check aws command
has aws

# check aws config file
check_file "${HOME}/.aws/config"

# create workingdir and sub directries
if [ ! -d ${WD} ]; then
	mkdir ${WD}
	cd ${WD}
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
	[ "$(stat --format='%a' ${CONF})" == "600" ] || logger_error "permission of ${CONF} is not 600"

	# read conf file
	. ${CONF}

	# check conf has enough information
	[ -z "${ENABLED}" -o -z "${BACKET}" -o -z "${BACKUPDIR}" -o -z "${NODE}" ] && logger_error "Not enough information in ${CONF}"
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
	eval "${command}" | tee -a $(logfile)
	
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
