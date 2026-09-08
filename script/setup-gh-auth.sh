#!/bin/bash

. "$(dirname "$0")/../bin/lib.sh"

has gh || exit 0

if ! gh auth status --active --hostname github.com >/dev/null 2>&1; then
    message info "GitHub CLI is not authenticated; skipping Git credential setup"
    exit 0
fi

mkdir -p "${HOME}/.config/git"
GIT_CONFIG_GLOBAL="${HOME}/.config/git/config.gh" gh auth setup-git --hostname github.com
