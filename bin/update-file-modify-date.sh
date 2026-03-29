#!/bin/bash

#/
#/ Usage:
#/
#/ update-file-modify-date.sh
#/ VERBOSE=true update-file-modify-date.sh
#/

set -e

. "$(dirname $0)/lib.sh"

has exiftool || abort "exiftool is not installed"

echo "Updating FileModifyDate..."

if [ -n "$VERBOSE" ]; then
    find . -type f -name "*.jpg" | while read -r FILE; do
        FILE_MODIFY_DATE=$(exiftool -s -s -s -d "%Y-%m-%d %H:%M:%S" -FileModifyDate ${FILE})
        DATE_TIME_ORIGINAL=$(exiftool -s -s -s -DateTimeOriginal ${FILE})
        echo "${FILE#./}: ${FILE_MODIFY_DATE} -> ${DATE_TIME_ORIGINAL}"
    done
fi

# As a side effect, btime will also get updated
exiftool -progress -r -overwrite_original "-FileModifyDate<DateTimeOriginal" .
