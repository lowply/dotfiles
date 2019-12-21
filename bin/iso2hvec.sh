#!/bin/bash

usage(){
	echo "Usage: $(basename $0) <src.iso> <target.mp4>"
	echo "Example: $(basename $0) /path/to/dvd.iso /path/to/file.mp4"
	exit 1
}

[ $# -ne 2 ] && usage
SRC=${1}
TGT=${2}
echo ${SRC} | grep -q ".iso" || usage
echo ${TGT} | grep -q ".mp4" || usage

DIRNAME=$(dirname ${TGT})
FILENAME=$(echo ${TGT} | sed -e 's/^.*\///' | sed -e 's/\..*$//')

date > ${DIRNAME}/${FILENAME}.log
/usr/local/bin/HandBrakeCLI \
	--input ${SRC} \
	--output ${TGT} \
	--optimize \
	--deinterlace \
	--all-subtitles \
	--main-feature \
	--encoder x265 \
	>> ${DIRNAME}/${FILENAME}.log 2>&1 &

echo "Converting ${SRC} to ${TGT}..."
echo ""
echo "To check the progress: tail -f ${DIRNAME}/${FILENAME}.log"
echo "To limit CPU usage:    cpulimit -p $(pidof HandBrakeCLI) -l 200"
echo "To abort:              killall HandBrakeCLI"
