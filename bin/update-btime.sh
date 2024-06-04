#!/bin/bash

set -e

. $(dirname $0)/lib.sh

has exiftool

# This isn't timezone compatible. The only way to modify the birth date
# as I wish when outside of JST is to change the OS timezone to JST
# before running this script.
for x in $(ls *.jpg)
do
    CURRENT=$(/bin/date -r $(/usr/bin/stat -f "%B" ${x}) "+%Y-%m-%d %H:%M:%S")
    DATE_CREATED_UNIX=$(exiftool -DateCreated ${x} -d %s | cut -d ":" -f 2 | xargs)
    UPDATED=$(/bin/date -r ${DATE_CREATED_UNIX} "+%Y-%m-%d %H:%M:%S")
    BTIME=$(/bin/date -r ${DATE_CREATED_UNIX} '+%m/%d/%Y %I:%M:%S %p')
    echo "Updating BTIME for ${x}. current: ${CURRENT}, updated: ${UPDATED}"
    SetFile -d "${BTIME}" ${x}
done
