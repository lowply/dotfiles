#!/bin/bash

abort(){
	echo ${1}
	exit 1
}

usage(){
	abort "Usage: AWSPROFILE=\"profile\" $(basename "$0") <domain>"
}

DOMAIN="${1}"
[ -z "${AWSPROFILE}" ] && usage
[ -z "${DOMAIN}" ] && usage

CERTDIR="file:///Users/lowply/.dehydrated/certs/${DOMAIN}"
ACM="aws --profile ${AWSPROFILE} --region us-east-1 acm"
ARN_JSON=$(${ACM} list-certificates --query "CertificateSummaryList[?DomainName==\`${DOMAIN}\`].CertificateArn")
ARN_JSON_LEN="$(echo ${ARN_JSON} | jq length)"

import(){
	ARN="${1}"
	OPT="${OPT} --certificate ${CERTDIR}/cert.pem"
	OPT="${OPT} --private-key ${CERTDIR}/privkey.pem"
	OPT="${OPT} --certificate-chain ${CERTDIR}/chain.pem"
	if [ ! -z "${ARN}" ]; then
		OPT="${OPT} --certificate-arn ${ARN}"
	fi

	${ACM} import-certificate ${OPT}
}

if [ ${ARN_JSON_LEN} -eq 0 ]; then
	echo "Importing a certificate..."
	import
elif [ ${ARN_JSON_LEN} -eq 1 ]; then
	ARN=$(echo ${ARN_JSON} | jq -r .[0])
	echo "There's already a certificate with domain ${DOMAIN}"
	echo "Renewing ARN: ${ARN}..."
	import ${ARN}
else
	abort "There are more than one certificate is registered. Plesae check them from AWS Console."
fi
