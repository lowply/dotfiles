#!/bin/bash

#
# Amazon Linux AMI 2014.03.2 (HVM) ami-29dc9228
#

#
# http://blog.kenjiskywalker.org/blog/2014/01/07/aws-cli-request-spot-instances/
#

type jq > /dev/null 2>&1 || { echo "Please install jq and run again" && exit 1; }
type aws > /dev/null 2>&1 || { echo "Please install jq and run again" && exit 1; }

AMI="ami-29dc9228"
INSTANCE_TYPE="t2.micro"
PRICE="0.1"
KEYPAIR="sho"
AZ="ap-northeast-1c"
SUBNET="subnet-b92201ff"
#USER_DATA=`echo "${HOST}" | openssl enc -base64`
USER_DATA="file://user_data.sh"
REGION="ap-northeast-1"
SECURITY_GROUPS="\"sg-28f5eb44\""
IAMROLE="arn:aws:iam::829087378211:instance-profile/ec2admin"

rm -f /tmp/launch_config.json
cat << EOF >> /tmp/launch_config.json
{
  "ImageId": "${AMI}",
  "KeyName": "${KEYPAIR}",
  "UserData": "${USER_DATA}"
  "InstanceType": "${INSTANCE_TYPE}",
  "Placement": {
    "AvailabilityZone": "${AZ}"
  },
  "Monitoring": {
    "Enabled": true
  },
  "SubnetId": "${SUBNET}",
  "SecurityGroupIds": [
    ${SECURITY_GROUPS}
  ],
  "IamInstanceProfile" : {
    "Arn" : "${IAMROLE}"
  }
}
EOF

case "${1}" in
spot)
	### PUT SPOT_REQUEST
	aws ec2 request-spot-instances --spot-price ${PRICE} --region ${REGION} --launch-specification file:///tmp/launch_config.json > /tmp/spot_request.json
	SIR_ID=`jq '.SpotInstanceRequests[0] | .SpotInstanceRequestId' /tmp/spot_request.json --raw-output`

	echo "[INFO] SpotInstanceRequestID: ${SIR_ID}";

	### GET SPOT_INSTANCE INSTANCE_ID
	rm -f /tmp/spot_instance.json

	aws ec2 describe-spot-instance-requests --spot-instance-request-ids ${SIR_ID} --region ${REGION} > /tmp/spot_instance.json
	INSTANCE_ID=`jq '.SpotInstanceRequests[0] | .InstanceId' /tmp/spot_instance.json --raw-output`

	while [ "${INSTANCE_ID}" == "null" ]
	do
		aws ec2 describe-spot-instance-requests --spot-instance-request-ids ${SIR_ID} --region ${REGION} > /tmp/spot_instance.json
		INSTANCE_ID=`jq '.SpotInstanceRequests[0] | .InstanceId' /tmp/spot_instance.json --raw-output`

		sleep 10
	done

	echo "[INFO] INSTANCE_ID: ${INSTANCE_ID}";
;;
normal)
	aws ec2 run-instances \
	--image-id ${AMI} \
	--subnet-id ${SUBNET} \
	--count 1 \
	--instance-type t2.micro \
	--key-name ${KEYPAIR} \
	--associate-public-ip-address \
	#--user-data ${USER_DATA}
	#--block-device-mappings file://ebs.json \
;;
*)
	echo "Usage: ${0} {spot|normal}"
esac



# aws ec2 run-instances \
# --image-id ami-0d13700c \
# --subnet-id subnet-de7e2398 \
# --count 1 \
# --instance-type m1.small \
# --key-name sho \
# --block-device-mappings file:///root/aws/ebs.json

#	#
#	# create volume
#	#
#	aws ec2 create-volume --size 30 --availability-zone ap-northeast-1b
#	
#	#
#	# add tags
#	#
#	aws ec2 create-tags --resources i-8443bc81 --tags Key=Name,Value=Testing
#	
#	#
#	# stop ec2 instance
#	#
#	aws ec2 stop-instances --instance-ids i-8443bc81
#	
#	#
#	# terminate instance
#	#
#	aws ec2 terminate-instances --instance-ids i-8443bc81
#
#	#
#	# list all EIPs
#	#
#	aws ec2 describe-addresses
#
#	#
#	# associate EIP to instance
#	#
#	aws ec2 associate-address --instance-id i-1933ec1e --allocation-id eipalloc-c24753a0
#	
#	#
#	# how to expand root device
#	#
#	resize2fs /dev/xvda1
