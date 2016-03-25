#!/bin/bash

# ------------------------------
# Stop SSH port forwarding
# ------------------------------

. $(dirname $0)/lib.sh

CONF="${HOME}/.supervisord_access"
DAEMON="pf22"

has stat

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

if [ -x /usr/bin/supervisorctl ]; then
	# Be sure that socket file configured right permission in /etc/supervisord.conf
	# so that an user can access via console and web UI. Example:
	# ...
	# [unix_http_server]
	# file=/var/run/supervisor.sock
	# chmod=0770
	# chown=username:nginx
	# ...
	SUPERVISOR="/usr/bin/supervisorctl -u ${USER} -p ${PASS}"
else
	error "Supervisor was not found. If you are using pyenv, switch to system and install supervisor via pip."
fi

STATUS="$(${SUPERVISOR} status ${DAEMON} | awk '{print $2}')"

if [ "${STATUS}" = "RUNNING" ]; then
	${SUPERVISOR} stop ${DAEMON}
	logger "Stopped ${DAEMON}"
else
	logger "${DAEMON} is not running"
fi
