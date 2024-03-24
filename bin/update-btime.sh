#!/bin/bash

set -e

for x in $(ls *.jpg)
do
    CURRENT=$(stat ${x} | grep Birth | cut -d ' ' -f 3-4 | cut -d '.' -f 1)
    UPDATED=$(exiftool -DateCreated ${x} -d '%Y-%m-%d %H:%M:%S' | cut -s -d ':' -f 2- | xargs)
    echo "Updating BTIME for ${x}. current: ${CURRENT}, updated: ${UPDATED}"
    BTIME=$(exiftool -DateCreated ${x} -d '%m/%d/%Y %I:%M:%S %p' | cut -s -d ':' -f 2- | xargs)
    SetFile -d "${BTIME}" ${x}
done
