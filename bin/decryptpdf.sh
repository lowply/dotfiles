#!/bin/bash

# ------------------------------
# Unlock encrypted PDF file
# ------------------------------

. $(dirname $0)/lib.sh

ensure_args $# 1 "Usage: $0 <filename>"

has qpdf

ensure_file $1

read -sp "Password: " PASSWORD
ORIGINAL=${1}
FILENAME=$(echo ${ORIGINAL} | sed -e 's/.pdf//g')
qpdf --password=${PASSWORD} --decrypt ${ORIGINAL} ${FILENAME}_.pdf
