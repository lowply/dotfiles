#!/usr/bin/env bash

if [ -d ~/.pyenv ]; then
	eval "$(~/.pyenv/bin/pyenv init -)"
	SUPERVISOR=/root/.pyenv/shims/supervisorctl
elif [ -x /usr/bin/supervisorctl ]; then
	SUPERVISOR=/usr/bin/supervisorctl
else
	echo "supervisor is not installed"	
	exit 1
fi

${SUPERVISOR} stop pf22
