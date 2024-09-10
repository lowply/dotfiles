#!/bin/bash

#/
#/ Usage: source sshauthsock.sh
#/
#/ Only supports Codespaces
#/

[ -n "${CODESPACES}" ] || exit 0

# Prevent this script to run
echo $- | grep -q i || { echo "source this script, don't run"; exit 1; }

# Not using pipe and while to make env var exportable
for SOCK in $(find /tmp/ssh-* -type s 2>/dev/null); do
    if SSH_AUTH_SOCK=${SOCK} ssh-add -l >/dev/null 2>&1; then
        echo "Setting SSH_AUTH_SOCK to ${SOCK}"
        export SSH_AUTH_SOCK=${SOCK}
        break
    fi
done

