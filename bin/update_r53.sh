#!/bin/bash

set -e

usage(){
	echo "Usage  : ./update_r53.sh [domain] [type] [record] [TTL] [awscli profile]>"
	echo "Example: ./update_r53.sh test.lowply.com A 192.168.1.0 300 private"
	exit 1
}

error(){
	echo "Error: ${1}"
	exit 1
}

type aws >/dev/null 2>&1 || error "awscli is not installed"
type jq >/dev/null 2>&1 || error "jq is not installed"

[ $# -ne 5 ] && usage
[ -d ${HOME}/.cache ] || mkdir ${HOME}/.cache 

LOGFILE="${HOME}/.cache/update_r53.log"
BATCHFILE="${HOME}/.cache/update_r53_batch.json"
DATE=$(date)
FQDN=$1
TYPE=$2
RECORD=$3
TTL=$4
PROFILE=$5

TLD=$(echo ${FQDN} | awk -F. '{print $NF}')
DOMAIN=$(echo ${FQDN} | awk -F. '{print $(NF-1)}').${TLD}
SUBDOMAIN=$(echo ${FQDN} | sed "s/\.${DOMAIN}//g")
R53="aws --profile ${PROFILE} route53"
HOSTED_ZONE_ID=$(${R53} list-hosted-zones --output json | jq -r ".HostedZones[] | select(.Name == \"${DOMAIN}.\").Id" | sed -e 's/\/hostedzone\///g')

[ -z "${HOSTED_ZONE_ID}" ] && error "\"${DOMAIN}\" not found in your Route53 zones."

if [ ${TYPE} == "TXT" ]; then
	RECORD="\\\"${RECORD}\\\""
fi

cat << EOT > ${BATCHFILE}
{
	"Comment": "Updated by updater53.sh",
	"Changes": [
		{
			"Action": "UPSERT",
			"ResourceRecordSet": {
				"Name": "${SUBDOMAIN}.${DOMAIN}",
				"Type": "${TYPE}",
				"TTL": ${TTL},
				"ResourceRecords": [
					{
						"Value": "${RECORD}"
					}
				]
			}
		}
	]
}
EOT

RESULT=$(${R53} change-resource-record-sets --hosted-zone-id ${HOSTED_ZONE_ID} --change-batch "file://${BATCHFILE}")

cat << EOL >> ${LOGFILE}

Executed on     : ${DATE}
Hosted zone ID  : ${HOSTED_ZONE_ID}
Public DNS name : ${FQDN}
Type            : ${TYPE}
Record          : ${RECORD}
TTL             : ${TTL}
Used profile    : ${PROFILE}
EOL

CHANGE_ID=$(echo ${RESULT} | jq -r .ChangeInfo.Id | sed -e 's/\/change\///g')
echo "Change requested"
echo "${RESULT}"

while true
do
	STATUS=$(${R53} get-change --id ${CHANGE_ID} | jq -r .ChangeInfo.Status)
	echo "Status: ${STATUS}"
	if [ "${STATUS}" = "INSYNC" ]; then
		echo "Done"
		break
	fi
	sleep 2
done

echo "Checking result..."
sleep 2
echo "host -t ${TYPE} ${FQDN}"
host -t ${TYPE} ${FQDN}
