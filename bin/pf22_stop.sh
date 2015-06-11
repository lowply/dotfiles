#!/usr/bin/env bash

if [ -d ~/.pyenv ]; then
	eval "$(~/.pyenv/bin/pyenv init -)"
	SUPERVISOR=/root/.pyenv/shims/supervisorctl
elif [ -x /usr/bin/supervisorctl ]; then
	SUPERVISOR=/usr/bin/supervisorctl
else
	echo "supervisor is not installed" >&2
	exit 1
fi

[ -z "$(supervisorctl status | grep pf22 | grep RUNNING)" ] && { echo "pf22 is not running" >&2; exit 1; }

${SUPERVISOR} stop pf22
