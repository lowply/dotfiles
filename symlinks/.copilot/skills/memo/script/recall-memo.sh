#!/bin/bash

set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$script_dir/lib.sh"

if [ "$#" -eq 0 ]; then
  echo "Usage: $(basename "$0") <query>"
  exit 1
fi

query="$*"
resolve_repository
find_repository_memos
find_memo_match "$query"

echo "TOP_MATCH=$top_path"
echo "MATCH_COUNT=1"
echo "CANDIDATES:"
printf '1. [%s] %s :: %s\n' "$match_reason" "$top_path" "$match_line"
