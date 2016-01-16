#!/usr/bin/env bash

CONF="${HOME}/.supervisord_access"
LOGFILE="/var/log/supervisor/stop.log"
DAEMON="pf22"

logger(){
	echo "$(date): [Info] ${1}" | tee -a ${LOGFILE}
}

error(){
	echo "$(date): [Error] ${1}" | tee -a ${LOGFILE} 1>&2 
	exit 1
}

# check if stat is installed
type stat > /dev/null 2>&1 || error "stat is not installed"

# if conf file does not exist, create it
if [ ! -f ${CONF} ]; then
	cat <<- EOL > ${CONF}
		USER=""
		PASS=""
	EOL
	chmod 600 ${CONF}
	error "${CONF} created, please update it"
else
	# check if conf file exists with permission 600
	[ "$(stat --format='%a' ${CONF})" == "600" ] || error "Permission of ${CONF} is not 600"

	# load conf
	. ${CONF}

	# check conf file has enough information
	[ -z "${USER}" -o -z "${PASS}" ] && error "Not enough information in ${CONF}"
fi

if [ -d ~/.pyenv ]; then
	eval "$(~/.pyenv/bin/pyenv init -)"
	SUPERVISOR="/root/.pyenv/shims/supervisorctl -u ${USER} -p ${PASS}"
elif [ -x /usr/bin/supervisorctl ]; then
	SUPERVISOR="/usr/bin/supervisorctl -u ${USER} -p ${PASS}"
else
	echo "supervisor is not installed" >&2
	exit 1
fi

STATUS="$(${SUPERVISOR} status ${DAEMON} | awk '{print $2}')"

if [ "${STATUS}" = "RUNNING" ]; then
	logger "$(${SUPERVISOR} stop ${DAEMON})"
else
	error "${DAEMON} is not running."
fi
