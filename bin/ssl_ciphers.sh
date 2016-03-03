#!/bin/bash

# ------------------------------
# Check available SSL Ciphers
# ------------------------------

. $(dirname $0)/lib.sh

check_args $# 1 "Usage: $0 <dns/ip>:<port>"

has openssl

# OpenSSL requires the port number.
SERVER=$1
DELAY=0

echo "Checking default negotiation:"
echo -n | openssl s_client -connect $SERVER 2>&1 | egrep '(  Protocol|  Cipher)'

ciphers=$(openssl ciphers 'ALL:eNULL' | sed -e 's/:/ /g')

echo
echo "Available Ciphers:"

for cipher in ${ciphers[@]}
do
result=$(echo -n | openssl s_client -cipher "$cipher" -connect $SERVER 2>&1)
if [[ "$result" =~ "Cipher is ${cipher}" || "$result" =~ "Cipher    :" ]] ; then
  echo "$cipher ENABLED"
fi
sleep $DELAY
done

logger "done"
