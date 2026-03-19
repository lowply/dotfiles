#!/bin/bash

#/
#/ Usage: update-file-modify-date.sh
#/

set -e

. "$(dirname $0)/lib.sh"

has exiftool || abort "exiftool is not installed"

exiftool "-FileModifyDate<DateTimeOriginal" -ext jpg -v .
