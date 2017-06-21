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
#/ Example Config:
#/ 
#/ -------------------- 
#/ {
#/ 	"enabled": true,
#/ 	"profile": "default",
#/ 	"bucket": "bucket",
#/ 	"dir": "backup",
#/ 	"node": "hostname",
#/ 	"targets": [
#/ 		{
#/ 			"path": "/home",
#/ 			"exclude": [
#/				"*.ssh/*",
#/				"*.aws/*",
#/				"*.cache/*",
#/				"*.bash-git-prompt/*",
#/				"*.log/*",
#/				"*.nodenv/*",
#/				"*.npm/*",
#/				"*.cpanm/*",
#/				"*.pyenv/*",
#/				"*.rbenv/*",
#/				"*.node-gyp/*",
#/				"*.gem/*",
#/				"*.github-backup-utils/*",
#/				"*.terminfo/*",
#/				"*dotfiles/*",
#/				"*src/*",
#/				"*bin/*",
#/				"*pkg/*",
#/				"*node_modules/*",
#/				"*tmp/*",
#/				"*vendor/*",
#/				"*.sass-cache/*",
#/				"*.cache",
#/				".vim_tmp/*"
#/ 			]
#/ 		},
#/ 		{
#/ 			"path": "/etc",
#/ 			"exclude": [
#/ 				"httpd/logs/*",
#/ 				"selinux/*",
#/ 				"pki/*",
#/ 				"xdg/*"
#/ 			]
#/ 		}
#/ 	]
#/ }
#/ -------------------- 
#/ 

CONF="${HOME}/.config/s3backup.json"

usage() {
	grep '^#/' < ${0} | cut -c4-
	exit 1
}

jqr(){
	jq -r "${1}" ${CONF}
}

check_value(){
	if [ "$(jqr ${1})" == "null" ]; then
		logger_error"${1} is null"
		return 1
	fi

	if [ -z "$(jqr ${1})" ]; then
		logger_error "${1} is empty"
		return 1
	fi

	return 0
}

check_conf(){
	[ $# -ne 1 ] && abort "Wrong argument"
	if [ -f ${1} ]; then
		jq '.' ${1} > /dev/null 2>&1
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
				"node":"your_host_name",
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
	local ENABLED=$(jqr '.enabled')
	local PROFILE=$(jqr '.profile')
	local TARGETS=$(jqr '.targets[] | .path')
	local BUCKET=$(jqr '.bucket')
	local BACKUPDIR=$(jqr '.dir')
	local NODE=$(jqr '.node')
	local BASIC_OPTS="--profile ${PROFILE} --no-follow-symlinks --delete --storage-class REDUCED_REDUNDANCY"
	
	[ "${ENABLED}" != "true" ] && { echo "Backup is disabled."; return 1; }

	for TARGET in ${TARGETS}; do
		# Not using jqr because I need no-raw output here:
		local EXCLUDES=$(jq ".targets[] | select(.path == \"${TARGET}\") .exclude[]" ${CONF})
		local OPTS=${BASIC_OPTS}

		for EXCLUDE in ${EXCLUDES}; do
			local OPTS="${OPTS} --exclude ${EXCLUDE}"
		done

		if [ "${1}" == "test" ]; then
			CMD="aws s3 sync ${OPTS} --dryrun ${TARGET}/ s3://${BUCKET}/${BACKUPDIR}/${NODE}${TARGET}/"
		else
			logger "Starting backup for ${TARGET}..."
			logger "aws s3 sync ${OPTS} ${TARGET}/ s3://${BUCKET}/${BACKUPDIR}/${NODE}${TARGET}/"
			CMD="aws s3 sync ${OPTS} ${TARGET}/ s3://${BUCKET}/${BACKUPDIR}/${NODE}${TARGET}/ | tee -a $(logfile)"
		fi
		eval "${CMD}"
	done
}

clean(){
	local PROFILE=$(jqr '.profile')
	local BUCKET=$(jqr '.bucket')
	local BACKUPDIR=$(jqr '.dir')
	local NODE=$(jqr '.node')
	logger "Removing backup for ${TARGET}..."
	CMD="aws s3 --profile ${PROFILE} rm --recursive s3://${BUCKET}/${BACKUPDIR}/${NODE}/ | tee -a $(logfile)"
	logger "${CMD}"
	eval "${CMD}"
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
