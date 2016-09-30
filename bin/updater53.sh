#!/bin/bash

TTL=60
LOGFILE="${HOME}/.cache/update_r53.log"
BATCHFILE="${HOME}/.cache/update_r53_batch.json"
DATE=$(date)
FQDN=$1
IP=$2
PROFILE=$3

usage(){
	echo "Usage:   ./update_r53.sh [domain] [IP] [awscli profile (optional)]>"
	echo "Example: ./update_r53.sh lowply.com 192.168.1.0 personal"
	echo "    Only use _subdomain.domain.tld_ format for the A record."
	echo "    If profile is empty, default profile will be used"
	exit 1
}

error(){
	echo "Error: ${1}"
	exit 1
}

type aws >/dev/null 2>&1 || error "awscli is not installed"
type jq >/dev/null 2>&1 || error "jq is not installed"

[ $# -lt 2 ] && usage
[ $# -gt 3 ] && usage
[ -z ${PROFILE} ] && PROFILE="default"

SUBDOMAIN=$(echo ${FQDN} | awk -F. '{print $1}')
DOMAIN=$(echo ${FQDN} | sed "s/${SUBDOMAIN}\.//g")
HOSTED_ZONE_ID=$(aws --profile ${PROFILE} route53 list-hosted-zones --output json | jq -r ".HostedZones[] | select(.Name == \"${DOMAIN}.\").Id" | sed -e 's/\/hostedzone\///g')

[ -z "${HOSTED_ZONE_ID}" ] && error "\"${DOMAIN}\" not found in your Route53 zones."

cat << EOL >> ${LOGFILE}

Executed on     : ${DATE}
Hosted zone ID  : ${HOSTED_ZONE_ID}
Public DNS name : ${SUBDOMAIN}.${DOMAIN}
IP address      : ${IP}
Used profile    : ${PROFILE}
EOL

cat << EOT > ${BATCHFILE}
{
"Comment": "Updated by updater53.sh",
"Changes": [
	{
	"Action": "UPSERT",
	"ResourceRecordSet": {
		"Name": "${SUBDOMAIN}.${DOMAIN}",
		"Type": "A",
		"TTL": ${TTL},
		"ResourceRecords": [
		{
			"Value": "${IP}"
		}
		]
	}
	}
]
}
EOT

aws --profile ${PROFILE} route53 change-resource-record-sets --hosted-zone-id ${HOSTED_ZONE_ID} --change-batch "file://${BATCHFILE}"
