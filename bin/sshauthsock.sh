#!/bin/bash

#/
#/ Usage: sshauthsock.sh
#/
#/ Only supports Codespaces
#/

set -e

. "$(dirname $0)/lib.sh"

[ -z "${CODESPACES}" ] && usage

find /tmp/ssh-* -type s 2>/dev/null | while IFS= read -r SOCK; do
    if SSH_AUTH_SOCK=${SOCK} ssh-add -l > /dev/null; then
        echo "Setting SSH_AUTH_SOCK to ${SOCK}"
        export SSH_AUTH_SOCK=${SOCK}
        break
    fi
done
