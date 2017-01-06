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

clean_challenge() {
    local DOMAIN="${1}" TOKEN_FILENAME="${2}" TOKEN_VALUE="${3}"
}

deploy_cert() {
    local DOMAIN="${1}" KEYFILE="${2}" CERTFILE="${3}" FULLCHAINFILE="${4}" CHAINFILE="${5}" TIMESTAMP="${6}"
}

unchanged_cert() {
    local DOMAIN="${1}" KEYFILE="${2}" CERTFILE="${3}" FULLCHAINFILE="${4}" CHAINFILE="${5}"
}

function invalid_challenge(){
    local DOMAIN="${1}" RESPONSE="${2}"
	abort "Error: ${DOMAIN} / Response: ${RESPONSE}"
}

renew(){
	[ $# != 1 ] && usage
	has dehydrated
	has lacrosse
	local CONFIG="${HOME}/.dehydrated/config"
	dehydrated --config ${CONFIG} --cron --domain ${1} --hook ${0} --challenge dns-01
}

HANDLER="$1"; shift
"$HANDLER" "$@"
