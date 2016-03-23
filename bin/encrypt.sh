#!/bin/bash

. $(dirname $0)/lib.sh

has openssl
has tar

enc(){
	DIR=$(echo ${DIR} | sed -e 's/\///g')
	FILENAME=$(echo "${DIR}.tar.gz.enc")
	[ -d ${DIR} ] || { echo "Directory ${DIR} not found"; exit 1; }
	[ -f ${FILENAME} ] && { echo "File ${FILENAME} already exists"; exit 1; }
	tar cz ${DIR} | openssl enc -aes-256-cbc -e > ${DIR}.tar.gz.enc
}

dec(){
	DIRNAME=$(echo ${ENCFILE} | sed -e 's/.tar.gz.enc//g')
	[ -d ${DIRNAME} ] && { echo "Directory ${DIRNAME} already exists"; exit 1; }
	[ -f ${ENCFILE} ] || { echo "File ${ENCFILE} was not found"; exit 1; }
	openssl aes-256-cbc -d -in ${ENCFILE} | tar xz
}

usage(){
    echo $"Usage: {enc <directory>|dec <encrypted file>}"
	exit 1
}

[ $# -eq 2 ] || usage

case "$1" in
  enc)
	DIR=${2}
    enc
    ;;
  dec)
	ENCFILE=${2}
    dec
	;;
  *)
  	usage
esac

