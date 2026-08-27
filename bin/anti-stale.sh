#!/bin/bash

set -euo pipefail

usage() {
  echo "Usage: anti-stale.sh <keep|fundamentals> <issue-url>" >&2
  exit 2
}

[ "$#" -eq 2 ] || usage

label=$1
issue_url=$2

case "$label" in
  keep|fundamentals) ;;
  *) usage ;;
esac

gh issue reopen "$issue_url"
gh issue edit "$issue_url" \
  --remove-label "stale,stale-closed" \
  --add-label "$label"
