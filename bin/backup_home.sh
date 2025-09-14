#!/bin/bash

#= Usage: backup_home.sh /path/to/target/
#= This script backs up the user's home directory to a target location.
#= Reads ~/.config/backup_home.filter for addiginal custom filters

usage(){
    grep "^#=.*" "$0" | sed 's/^#= *//'
    exit 1
}

set -euo pipefail

uname | grep -q "Darwin" || { echo "Only macOS is supported"; exit 1; }

[ $# -ne 1 ] && usage

DST="$1"

# Directory check
[ -d "$DST" ] || { echo "Target directory $DST does not exist"; exit 1; }

# Ensure trailing slash
SRC="${HOME%/}/"
DST="${DST%/}/"

FILTER_FILE=$(mktemp)
# trap 'rm -f "$FILTER_FILE"' EXIT


cat << EOF > "$FILTER_FILE"
# Global ignore
- .DS_Store
- *node_modules*

# Per directory
- .bundle
- .cache
- .cargo
- .n
- .node
- .npm
- .rbenv
- .Trash

# Some directories in ~/Library
- Library/Application Support
- Library/Caches
- Library/Containers
- Library/Group Containers
- Library/Developer
- Library/Logs
- Library/CloudStorage

EOF

[ -f ~/.config/backup_home.filter ] && cat ~/.config/backup_home.filter >> $FILTER_FILE

rsync -av --delete \
    --filter=". $FILTER_FILE" \
    --log-file="${HOME}/Desktop/rsync.log" \
    "${SRC}" "${DST}"
