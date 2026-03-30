#!/bin/bash

# For SSH commit signing in Codespaces

[ -z "${CODESPACES}" ] && return

find_ssh_auth_sock() {
    for SOCK in $(find /tmp/ssh-* -type s 2>/dev/null); do
        if SSH_AUTH_SOCK=${SOCK} ssh-add -l >/dev/null 2>&1; then
            echo "Setting SSH_AUTH_SOCK to ${SOCK}"
            export SSH_AUTH_SOCK=${SOCK}
            break
        fi
    done
}

git() {
    case "$1" in
        commit|rebase|merge|tag)
            [ -S "${SSH_AUTH_SOCK}" ] || find_ssh_auth_sock
            ;;
    esac
    command git "$@"
}
