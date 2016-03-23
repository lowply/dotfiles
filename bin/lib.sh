#/bin/bash

# ------------------------------
# Variables
# ------------------------------

DATE=$(date +%y%m%d.%H%M%S)

# ------------------------------
# Methods
# ------------------------------

logfile(){
	LOGDIR="${HOME}/.log"
	LOGFILE="${LOGDIR}/$(basename $0).log"
	[ -d ${LOGDIR} ] || mkdir ${LOGDIR}
	[ -f ${LOGFILE} ] || touch ${LOGFILE}
	echo ${LOGFILE}
}

logger(){
	LOGFILE=$(logfile)
	echo "$(date): [Info] ${1}" | tee -a ${LOGFILE}
}

error(){
	LOGFILE=$(logfile)
	echo "$(date): [Error] ${1}" | tee -a ${LOGFILE} 1>&2 
	exit 1
}

has(){
	type ${1} >/dev/null 2>&1 || error "Command not found: ${1}"
}

automkdir(){
	[ -d "${1}" ] || mkdir ${1}
}

check_args(){
	[ ${1} -eq ${2} ] || error "${3}"
}

check_dir(){
	[ -d ${1} ] || error "No such directory: ${1}"
}

check_file(){
	[ -f ${1} ] || error "No such file: ${1}"
}

check_os(){
	echo ${OSTYPE} | grep ${1} > /dev/null || error "Not a Linux OS"
}
