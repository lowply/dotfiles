#!/bin/bash

usage(){
	echo "$(basename $0) <src> <name.mp4>"
	exit 1
}

[ $# -ne 2 ] && usage

SRC=${1}
TGT=${2}
DIRNAME=$(dirname ${TGT})
FILENAME=$(echo ${TGT} | sed -e 's/^.*\///' | sed -e 's/\..*$//')

# --stop-at duration:1440 \

date > ${DIRNAME}/${FILENAME}.log
/usr/local/bin/HandBrakeCLI \
	--input ${SRC} \
	--output ${TGT} \
	--optimize \
	--deinterlace \
	--all-subtitles \
	--encoder x265 >> ${DIRNAME}/${FILENAME}.log 2>&1 &

echo "Converting ${SRC} to ${TGT}..."
echo "tail -f ${DIRNAME}/${FILENAME}.log to see the progress"

PID=$(pidof HandBrakeCLI)
echo "$(ps auxw | grep HandBrakeCLI)" 
echo "Limiting PID: ${PID}" 
cpulimit -p ${PID} -l 200 
