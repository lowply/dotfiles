#!/bin/bash

set -e

. "$(dirname $0)/lib.sh"

has exiftool || abort "exiftool is not installed"

# This isn't timezone compatible. The only way to modify the birth date
# as I wish when outside of JST is to change the OS timezone to JST
# before running this script.
find . -type f -name "*.gz" | while IFS= read -r FILE; do
    CURRENT=$(/bin/date -r "$(/usr/bin/stat -f '%B' ${FILE})" "+%Y-%m-%d %H:%M:%S")
    DATE_CREATED_UNIX=$(exiftool -DateCreated "${FILE}" -d %s | cut -d ":" -f 2 | xargs)
    UPDATED=$(/bin/date -r "${DATE_CREATED_UNIX}" "+%Y-%m-%d %H:%M:%S")
    BTIME=$(/bin/date -r "${DATE_CREATED_UNIX}" '+%m/%d/%Y %I:%M:%S %p')
    echo "Updating BTIME for ${FILE}. current: ${CURRENT}, updated: ${UPDATED}"
    SetFile -d "${BTIME}" ${FILE}
done
