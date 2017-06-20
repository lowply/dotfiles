#!/bin/bash

#/
#/ s3backup - backup directories to Amazon S3
#/ 
#/ Prerequirements: aws-cli, jq
#/ Author: @lowply
#/ Config: ~/.config/s3backup.json
#/ Subcommands:
#/ 
#/ - sync:  Do sync
#/ - test:  Dry Run
#/ - clean: Remove all backups
#/

CONF="${HOME}/.config/s3backup.json"

usage() {
	grep '^#/' < ${0} | cut -c4-
	exit 1
}

readvalue(){
	[ $# -ne 1 ] && abort "Wrong argument"
	echo $(jq -Mcr "${1}" ${CONF})
}

check_value(){
	if [ "$(readvalue ${1})" == "null" ]; then
		logger_error"${1} is null"
		return 1
	fi

	if [ -z "$(readvalue ${1})" ]; then
		logger_error "${1} is empty"
		return 1
	fi

	return 0
}

check_conf(){
	[ $# -ne 1 ] && abort "Wrong argument"
	if [ -f ${1} ]; then
		jq -Mc '.' ${1} > /dev/null 2>&1
		if [ $? -ne 0 ]; then
			logger_error "Error parsing config: ${1}"
			return 1
		fi

		check_value ".enabled"
		check_value ".profile"
		check_value ".bucket"
		check_value ".dir"
		check_value ".node"

		[ $? -ne 0 ] && { echo "Wrong config"; return 1; }
		return 0
	else
		[ -d ${HOME}/.config ] || mkdir ${HOME}/.config
		cat <<- EOL | jq --tab '.' > ${1}
			{
				"enabled": true,
				"profile": "aws_profile",
				"bucket": "aws_bucket",
				"dir": "directory_in_bucket",
				"node":"your_node_name",
				"targets": [
					{
						"path":"/path/to/directory_A",
						"exclude":[
							"file_or_directory_to_exclude"
						]
					},
					{
						"path":"/path/to/directory_B",
						"exclude":[
							"file_or_directory_to_exclude"
						]
					}
				]
			}
		EOL
		message warn "Config ${1} is generated, please update it."
		return 1
	fi
}

sync(){
	local ENABLED=$(readvalue '.enabled')
	local PROFILE=$(readvalue '.profile')
	local TARGETS=$(readvalue '.targets[] | .path')
	local BUCKET=$(readvalue '.bucket')
	local BACKUPDIR=$(readvalue '.dir')
	local NODE=$(readvalue '.node')
	local BASIC_OPTS="--profile ${PROFILE} --no-follow-symlinks --delete --storage-class REDUCED_REDUNDANCY"
	
	[ "${ENABLED}" != "true" ] && { echo "Backup is disabled."; return 1; }

	for TARGET in ${TARGETS}; do
		local EXCLUDES=$(readvalue ".targets[] | select(.path == \"${TARGET}\") .exclude[]")
		local OPTS=${BASIC_OPTS}

		for EXCLUDE in ${EXCLUDES}; do
			local OPTS="${OPTS} --exclude ${EXCLUDE}"
		done

		if [ "${1}" == "test" ]; then
			aws s3 sync ${OPTS} --dryrun ${TARGET}/ s3://${BUCKET}/${BACKUPDIR}/${NODE}${TARGET}/
		else
			logger "Starting backup for ${TARGET}..."
			logger "aws s3 sync ${OPTS} ${TARGET}/ s3://${BUCKET}/${BACKUPDIR}/${NODE}${TARGET}/"
			aws s3 sync ${OPTS} ${TARGET}/ s3://${BUCKET}/${BACKUPDIR}/${NODE}${TARGET}/ | tee -a $(logfile)
		fi
	done
}

clean(){
	local PROFILE=$(readvalue '.profile')
	local BUCKET=$(readvalue '.bucket')
	local BACKUPDIR=$(readvalue '.dir')
	local NODE=$(readvalue '.node')
	logger "Removing backup for ${TARGET}..."
	logger "aws s3 --profile ${PROFILE} rm --recursive s3://${BUCKET}/${BACKUPDIR}/${NODE}/*"
	aws s3 --profile ${PROFILE} rm --recursive s3://${BUCKET}/${BACKUPDIR}/${NODE}/ | tee -a $(logfile)
}

main(){
	. $(dirname $0)/lib.sh

	# check jq command
	has jq

	# check aws command
	has aws

	# check aws config file
	check_file "${HOME}/.aws/config"

	# for multibyte filenames
	export LANG=en_US.UTF-8

	check_conf ${CONF}
	[ $? -ne 0 ] && exit 1

	HANDLER="${1}"
	shift

	case ${HANDLER} in
		"sync")
			sync
			[ $? -ne 0 ] && exit 1
		;;
		"test")
			sync test
		;;
		"clean")
			clean
		;;
		*)
			usage
		;;
	esac
}

main $@
