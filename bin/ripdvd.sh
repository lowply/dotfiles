#!/bin/bash

. $(dirname $0)/lib.sh

usage(){
	echo "Usage:"
	echo "    ${0} name"
	exit 1
}

convert_mp4(){
	local HBBIN=/Applications/HandBrakeCLI
	local DEVICE=${1}
	local TITLE=${2}

	[ -x ${HBBIN} ] || abort "HandBrakeCLI is not installed."
	[ -z ${TITLE} ] && abort "Title is not provided."
	[ -z ${DEVICE} ] && abort "Device is not provided."
	[ -f "${WORKDIR}/${TITLE}.mp4" ] && abort "${WORKDIR}/${TITLE} already exists."

	${HBBIN} -i ${DEVICE} -Z "High Profile" -s Japanese -o ${WORKDIR}/${TITLE}.mp4
}

check_conf(){
	if [ -f ${CONF} ]; then
		. ${CONF}
		[ -z ${WORKDIR} ] && abort "WORKDIR is empty. Please update ${CONF}"
	else
		cat <<- EOF > ${CONF}
			# Example: WORKDIR="/Volumes/Storage/DVD"
			WORKDIR=
		EOF
		abort "${CONF} is created. Please update it."
	fi
}

main(){
	CONF=${HOME}/.config/ripdvd.conf
	check_conf
	has dvdbackup
	[ $# -ne 1 ] && usage

	TITLE=${1}
	DISKNAME="DVD_VIDEO"

	DRUTIL_DVD=$(drutil status | grep -m 1 "Type: DVD-R")
	[ -z "${DRUTIL_DVD}" ] && abort "No DVD is inserted"

	RIPDIR="${WORKDIR}/.tmp"
	[ -d ${RIPDIR} ] && { echo "Removing old workdir..."; rm -rf ${RIPDIR}; }

	DEVICE=$(echo ${DRUTIL_DVD} | grep Name | sed -e 's/^.*Name: //')

	# avoid overwrite, check if there is already the same name iso image
	[ -e "${WORKDIR}/${TITLE}.iso" ] && abort "The same name of iso image is in this directory."

	# start ripping
	echo "Target : ${DEVICE}, Name : ${TITLE}"
	echo "Ripping..."
	dvdbackup -n ${DISKNAME} -i ${DEVICE} -M -p -o ${RIPDIR}

	# start making iso
	echo "Ripping done. Creating ISO diskimage..."
	hdiutil makehybrid -o ${WORKDIR}/${TITLE}.iso ${RIPDIR}/${DISKNAME} -iso -udf -udf-volume-name ${DISKNAME}

	# eject DVD and finish
	echo "ISO diskimage created. Ejecting disk..."
	drutil eject
}

main $@

