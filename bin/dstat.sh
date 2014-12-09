#!/bin/bash

echo ${OSTYPE} | grep "linux" || { echo "Not a Linux OS"; exit 1; }

_DISK=`df -h | grep -w "/" | awk '{print $1}'`
_DEVICE=`ifconfig | grep "^eth" | awk '{print $1}' | perl -pe 's/\n/,/g' | perl -pe 's/,$//g'`

echo dstat -cdnlt -N $_DEVICE,total -D $_DISK,total --top-io --top-bio --top-cpu --top-cputime --top-cputime-avg --top-mem
dstat -cdnlt -N $_DEVICE,total -D $_DISK,total --top-io --top-bio --top-cpu --top-cputime --top-cputime-avg --top-mem
