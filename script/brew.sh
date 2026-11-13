#!/bin/bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

case "${OSTYPE}" in
    darwin*) ;;
    *)
        echo "Homebrew setup is only supported on macOS." >&2
        exit 1
        ;;
esac

export PATH="${PATH}:/opt/homebrew/bin:/usr/local/bin"
if ! command -v brew >/dev/null 2>&1; then
    echo "Install Homebrew before running this script." >&2
    exit 1
fi

brew bundle --file="${repo_root}/Brewfile"
