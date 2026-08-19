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

updated_at="$(date '+%Y-%m-%dT%H:%M:%S%z')"
sed -i '' \
  -e 's/^status:.*/status: "done"/' \
  -e "s/^updated_at:.*/updated_at: \"$updated_at\"/" \
  "$top_path"

echo "Marked done: $top_path"
