#!/usr/bin/env bash

abort(){
	echo "${1}"
	exit 1
}

usage(){
	abort "Usage: ${0} example.com aws_profile <yes|no> / the third parameter is for wildcard certificate"
}

[ $# -ne 3 ] && usage
[ -f ${HOME}/.aws/credentials ] || abort "aws credentials not found"
[ -d ${HOME}/.acme.sh ] || abort "acme.sh not found"

DOMAIN=${1}
PROFILE=${2}
WILDCARD=${3}
AWS_ACCESS_KEY_ID="$(cat ~/.aws/credentials | grep "\[${PROFILE}\]" -A 2 | grep 'aws_secret_access_key' | sed -e 's/aws_secret_access_key = //')"
AWS_SECRET_ACCESS_KEY="$(cat ~/.aws/credentials | grep "\[${PROFILE}\]" -A 2 | grep 'aws_access_key_id' | sed -e 's/aws_access_key_id = //')"

if [ "${WILDCARD}" == "yes" ]; then
	${HOME}/.acme.sh/acme.sh --issue \
		-d ${DOMAIN} -d "*.${DOMAIN}" \
		--dns dns_aws
else
	${HOME}/.acme.sh/acme.sh --issue \
		-d ${DOMAIN} \
		--dns dns_aws
fi

