#!/bin/bash

# Let's Encrypt hook & renew
#
# Hook example:
# dehydrated --cron --domain example.com --hook letsencrypt.sh --challenge dns-01
#
# hook script example:
# https://github.com/lukas2511/letsencrypt.sh/blob/master/docs/examples/hook.sh

. $(dirname $0)/lib.sh

usage(){
	echo "Usage: ${0} renew example.com"
	exit 1
}

deploy_challenge() {
	local DOMAIN="${1}" TOKEN_FILENAME="${2}" TOKEN_VALUE="${3}"
	lacrosse _acme-challenge.${DOMAIN} TXT ${TOKEN_VALUE} 300 private
}

invalid_challenge(){
    local DOMAIN="${1}" RESPONSE="${2}"
	abort "Error: ${DOMAIN} / Response: ${RESPONSE}"
}

renew(){
	has dehydrated
	has lacrosse
	local BASEDIR="${HOME}/.dehydrated"
	local CONFIG="${BASEDIR}/config"
	[ $# != 1 ] && usage
	dehydrated --config ${CONFIG} --cron --domain ${1} --hook ${0} --challenge dns-01
}

HANDLER="$1"; shift
"$HANDLER" "$@"
