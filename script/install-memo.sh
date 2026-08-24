#!/bin/bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
install_dir="${HOME}/bin"
binary_path="${install_dir}/memo"

if ! command -v go >/dev/null 2>&1; then
    echo "Go is required to build the memo CLI." >&2
    exit 1
fi

mkdir -p "${install_dir}"
tmp="$(mktemp "${install_dir}/.memo.XXXXXX")"
trap 'rm -f "${tmp}"' EXIT

(cd "${repo_root}/tools/memo" && go build -trimpath -o "${tmp}" .)
chmod 755 "${tmp}"
mv "${tmp}" "${binary_path}"
trap - EXIT

echo "Installed memo CLI to ${binary_path}"
