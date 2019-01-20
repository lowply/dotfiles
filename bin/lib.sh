#/bin/bash

# ------------------------------
# Variables
# ------------------------------

DATE=$(date +%y%m%d_%H%M%S)

# ------------------------------
# Methods
# ------------------------------

logfile(){
	LOGDIR="${HOME}/.log/$(basename $0)"
	LOGFILE="${LOGDIR}/$(date +%y%m%d).log"

	automkdir ${LOGDIR}
	[ -f ${LOGFILE} ] || touch ${LOGFILE}
	echo ${LOGFILE}
}

logger(){
	LOGFILE=$(logfile)
	echo "$(date): [Info] ${1}" | tee -a ${LOGFILE}
}

logger_error(){
	LOGFILE=$(logfile)
	echo "$(date): [Error] ${1}" | tee -a ${LOGFILE} 1>&2
	exit 1
}

abort(){
	message error "${1}"
	exit 1
}

has(){
	type ${1} >/dev/null 2>&1 || abort "Command not found: ${1}"
}

automkdir(){
	[ -d "${1}" ] || mkdir -p ${1}
}

autotouchfile(){
    [ -f ${1} ] || touch ${1}
}

check_args(){
	[ ${1} -eq ${2} ] || abort "${3}"
}

check_dir(){
	[ -d ${1} ] || abort "No such directory: ${1}"
}

check_file(){
	[ -f ${1} ] || abort "No such file: ${1}"
}

check_os(){
	echo ${OSTYPE} | grep ${1} > /dev/null || abort "Not a Linux OS"
}

color(){
	case "${1}" in
		black) local COLOR="\e[30m" ;;
		red) local COLOR="\e[31m" ;;
		green) local COLOR="\e[32m" ;;
		yellow) local COLOR="\e[33m" ;;
		blue) local COLOR="\e[34m" ;;
		magenta) local COLOR="\e[35m" ;;
		cyan) local COLOR="\e[36m" ;;
		white) local COLOR="\e[37m" ;;
		*) local COLOR="\e[37m" ;;
	esac
    local RESET="\e[39m"
	printf "${COLOR}${2}${RESET}\n"
}

message(){
	case "${1}" in
	success)
		echo "[ $(color green OK) ] ${2}"
	;;
	info)
		echo "[ $(color blue INFO) ] ${2}"
	;;
	user)
		echo "[ $(color yellow ??) ] ${2}"
	;;
	warn)
		echo "[ $(color yellow WARN) ] ${2}"
	;;
	error)
		echo "[ $(color red ERROR) ] ${2}"
	;;
	fail)
		echo "[ $(color red FAIL) ] ${2}"
	;;
	*)
		echo "Incorrect Argument"
	;;
	esac
}
