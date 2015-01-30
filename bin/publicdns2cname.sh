#!/bin/bash

#
# /etc/rc.d/init.d/publicdns2cname
#
# chkconfig: 345 44 56
#

#
# need to run "aws configure" as root user
#

start() {
	TTL=60
	TAGNAME="cname"
	LOGFILE="/var/log/publicdns2cname.log"
	# cp -f /usr/share/zoneinfo/Japan /etc/localtime
	DATE=$(date)
	SELF_META_URL="http://169.254.169.254/latest/meta-data"
	MY_PUBLIC_DNS=$(curl ${SELF_META_URL}/public-hostname 2>/dev/null)
	MY_INSTANCE_ID=$(curl ${SELF_META_URL}/instance-id 2>/dev/null)

	CNAME=$(aws ec2 describe-tags --output text --query "Tags[?ResourceId==\`${MY_INSTANCE_ID}\`] | [?Key==\`${TAGNAME}\`].[Value]")
	SUBDOMAIN="ec2"
	SUBSUBDOMAIN=$(echo $CNAME | sed -e 's/\..*$//')
	DOMAIN=$(echo $CNAME | sed -e "s/[^.].${SUBDOMAIN}.//")
	HOSTED_ZONE_ID=$(aws route53 list-hosted-zones --output text --query "HostedZones[?Name==\`${DOMAIN}.\`].Id" | sed -e 's/\/hostedzone\///g')

cat << EOL >> ${LOGFILE}
Executed on ${DATE}
--------------------
Public DNS Name: ${MY_PUBLIC_DNS}
Instance ID: ${MY_INSTANCE_ID}
cname Tag: ${CNAME}
Hosted Zone ID: ${HOSTED_ZONE_ID}
Sub Sub Domain: ${SUBSUBDOMAIN}
Sub Domain: ${SUBDOMAIN}
Domain: ${DOMAIN}

EOL

	[ -z "${CNAME}" ] && { echo "Please setup cname tag for your Instance ID: ${MY_INSTANCE_ID}. Example: cname / ec2.example.com"; exit 1; }
	[ -z "${HOSTED_ZONE_ID}" ] && { echo "No hosted zone for \"${DOMAIN}\" found on your Route53 zones."; exit 1; }

	#
	# Update CNAME record
	#
cat << EOT > /tmp/aws_r53_batch.json
{
"Comment": "Assign AWS Public DNS as a CNAME of hostname",
"Changes": [
	{
	"Action": "UPSERT",
	"ResourceRecordSet": {
		"Name": "${CNAME}.",
		"Type": "CNAME",
		"TTL": ${TTL},
		"ResourceRecords": [
		{
			"Value": "${MY_PUBLIC_DNS}"
		}
		]
	}
	}
]
}
EOT

	aws route53 change-resource-record-sets --hosted-zone-id ${HOSTED_ZONE_ID} --change-batch file:///tmp/aws_r53_batch.json
	rm -f /tmp/aws_r53_batch.json

    return $?
}

stop()
{
    return 0
}

restart() {
    stop
    start
}

#
# Check environment
#
cat /etc/system-release | grep "Amazon Linux" > /dev/null 2>&1 || { echo "This host is not Amazon Linux"; exit 1; }
[ -f /root/.aws/config ] || { echo "Please configure awscli as root"; exit 1; }

case "$1" in
    start)
        start
        ;;
    stop)
        stop
        ;;
    restart)
        restart
        ;;
    *)
        echo "Usage: $0 {start|stop|restart}"
        RETVAL=2
esac
exit $RETVAL

