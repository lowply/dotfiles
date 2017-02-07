#!/usr/bin/env bash

# Let's Encrypt hook & renew
#
# Based on:
# https://github.com/lukas2511/dehydrated/blob/master/docs/examples/hook.sh

. $(dirname $0)/lib.sh

usage(){
	echo "Usage: AWSPROFILE=\"profile\" letsencrypt.sh renew example.com"
	exit 1
}

deploy_challenge() {
    local DOMAIN="${1}" TOKEN_FILENAME="${2}" TOKEN_VALUE="${3}"
	lacrosse _acme-challenge.${DOMAIN} TXT ${TOKEN_VALUE} 300 ${AWSPROFILE}
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

invalid_challenge() {
    local DOMAIN="${1}" RESPONSE="${2}"
}

request_failure() {
    local STATUSCODE="${1}" REASON="${2}" REQTYPE="${3}"
}

exit_hook() {
  :
}

renew(){
	[ $# != 1 ] && usage
	[ -z "${AWSPROFILE}" ] && usage
	has dehydrated
	has lacrosse
	local CONFIG="${HOME}/.dehydrated/config"
	dehydrated --config ${CONFIG} --cron --domain ${1} --hook ${0} --challenge dns-01
}

[ -z "$1" ] && usage

HANDLER="$1"; shift

if [[ "${HANDLER}" =~ ^(deploy_challenge|clean_challenge|deploy_cert|unchanged_cert|invalid_challenge|request_failure|exit_hook|renew)$ ]]; then
  "$HANDLER" "$@"
fi
