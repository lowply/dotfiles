#!/bin/bash

set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$script_dir/lib.sh"

if [ "$#" -ne 1 ] || [ -z "$1" ]; then
  echo "Usage: $(basename "$0") <kebab-case-name>"
  exit 1
fi

name="$1"
if [[ ! "$name" =~ ^[a-z0-9]+(-[a-z0-9]+)*$ ]]; then
  echo "Memo name must be kebab-case."
  exit 1
fi

resolve_repository

timestamp="$(date '+%Y-%m-%dT%H:%M:%S%z')"
date_prefix="$(date +%Y-%m-%d)"
memo_id="$(date +%s)"
memo_dir="${HOME}/.copilot/memo"
mkdir -p "$memo_dir"

file_path="${memo_dir}/${date_prefix}-${memo_id}-${repo_owner}-${repo_name}-${name}.md"
if [ -e "$file_path" ]; then
  echo "Memo file already exists: $file_path"
  exit 1
fi

cat >"$file_path" <<EOF
---
memo_id: "$memo_id"
summary: "TODO: add a 1-3 sentence summary"
status: "wip"
created_at: "$timestamp"
updated_at: "$timestamp"
---

# Memo note

TODO: add memo details.
EOF

echo "$file_path"
