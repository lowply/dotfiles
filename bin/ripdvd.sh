#!/bin/bash

. $(dirname $0)/lib.sh

usage(){
    echo "Usage:"
    echo "    ISO=<true|false> MP4=<true|false> TITLE=<title> WORKDIR=</path/to/dir>"
    echo "    ISO default to false"
    echo "    MP4 default to true"
    exit 1
}

# TODO 2025-02-28: Need to verify if this works as expected

main(){
    has dvdbackup
    has HandBrakeCLI

    [ -z "${TITLE}" ] && usage
    [ -z "${WORKDIR}" ] && usage

    CONVERT_TO_ISO="${ISO:-false}"
    CONVERT_TO_MP4="${MP4:-true}"

    DRUTIL_DVD=$(drutil status | grep -m 1 "Type: DVD-R")
    [ -z "${DRUTIL_DVD}" ] && abort "No DVD is inserted"
    DEVICE=$(echo ${DRUTIL_DVD} | grep Name | sed -e 's/^.*Name: //')

    TITLE_PATH="${WORKDIR}/${TITLE}"
    [ -d "${TITLE_PATH}" ] && abort "${TITLE_PATH} already exists."

    # start ripping
    echo "Running dvdbackup: ${DEVICE} ${TITLE}"
    dvdbackup -n ${TITLE} -i ${DEVICE} -M -p -o ${TITLE_PATH}

    if [ $CONVERT_TO_MP4 == "true" ]; then
        [ -f "${TITLE_PATH}.mp4" ] && abort "${TITLE_PATH}.mp4 already exists."
        echo "Creating mp4..."
        # DVDs are 720p and 30fps
        HandBrakeCLI -i ${TITLE_PATH} --main-feature -Z "Apple 720p30 Surround" -s Japanese -o ${TITLE_PATH}.mp4
    fi

    if [ $CONVERT_TO_ISO == "true" ]; then
        # avoid overwrite, check if there is already the same name iso image
        [ -f "${TITLE_PATH}.iso" ] && abort "${TITLE_PATH}.iso already exists."
        echo "Creating ISO diskimage..."
        hdiutil makehybrid -o ${TITLE_PATH}.iso ${TITLE_PATH} -iso -udf -udf-volume-name ${TITLE}
    fi

    # eject DVD and finish
    echo "Ejecting disk..."
    drutil eject

    echo "Done"
}

main $@

