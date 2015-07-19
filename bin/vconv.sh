#!/bin/bash

CPU_CORES=$(/usr/bin/getconf _NPROCESSORS_ONLN)
OPTIONS="-acodec libfaac -vcodec libx264 -pix_fmt yuv420p -aq 100 -crf 20 -vsync 1 -threads ${CPU_CORES}"

# -aq: audio quality. See https://ja.wikipedia.org/wiki/FFmpeg
# -ac: audio channel.
# -crf: video quality. See http://tutinoko.org/blog/2010/12/25/x264%E3%81%A7%E3%81%AEcrf%E5%80%A4%E3%81%AF%E3%81%A9%E3%82%8C%E3%81%8F%E3%82%89%E3%81%84%E3%81%8C%E9%81%A9%E5%88%87%E3%81%AA%E3%81%AE%E3%81%8B%EF%BC%9F/

mp4convert(){
	OUTPUT=$(echo "${1}" | sed -e "s/\.[^.]*$/.mp4/")
	ffmpeg -i "${1}" -acodec libfaac -vcodec libx264 -pix_fmt yuv420p -aq 100 -crf 20 -vsync 1 -threads ${CPU_CORES} "${OUTPUT}"
	#ffmpeg -i "${1}" ${OPTIONS} "${OUTPUT}"
	echo ffmpeg -i "${1}" "${OPTIONS}" "${OUTPUT}"
}

if [ "${1}" = "" ];then
	echo "Usage: v_convert.sh <all [extension] | combine [extension] | target_file>"
	exit 1
elif [ "${1}" = "all" ];then
	if [ "${2}" = "" ];then
		echo "Usage: v_convert.sh all [extension]"
		exit 1
	fi
	FILES=$(find . -type f -name "*.${2}")
	IFS="
	"
	for FILENAME in ${FILES}; do
		mp4convert ${FILENAME}
	done
elif [ "${1}" = "combine" ];then
	if [ "${2}" = "" ];then
		echo "Usage: v_convert.sh combine [extension]"
		exit 1
	fi
	FILES=$(find . -type f -name "*.${2}")
	FILENUM=$(find . -type f -name "*.${2}" | wc -l)
	if [ "${FILES}" = "" ];then
		echo "No list given"
		exit 1
	fi
	for FILENAME in ${FILES}; do
		INPUTS="${INPUTS} -i ${FILENAME}"
	done
	OUTPUT="combined.mp4"
	ffmpeg ${INPUTS} ${OPTIONS} -filter_complex "concat=n=${FILENUM}:v=1:a=1" "${OUTPUT}"
	echo ffmpeg ${INPUTS} -filter_complex "concat=n=${FILENUM}:v=1:a=1" "${OUTPUT}"
else
	mp4convert ${1}
fi

