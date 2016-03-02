#!/bin/bash

type qpdf >/dev/null 2>&1 || { echo "qpdf is not found"; exit 1; }
[ $# -eq 1 ] || { echo "Usage: ./decryptpdf.sh <filename>"; exit 1; }
[ -f $1 ] || { echo "No such PDF file in this directory"; exit 1; }

read -sp "Password: " PASSWORD
ORIGINAL=${1}
FILENAME=$(echo ${ORIGINAL} | sed -e 's/.pdf//g')

qpdf --password=${PASSWORD} --decrypt ${ORIGINAL} ${FILENAME}_.pdf
