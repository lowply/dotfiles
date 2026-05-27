#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Toggle Key Light
# @raycast.mode compact

# Optional parameters:
# @raycast.icon 💡

# Documentation:
# @raycast.description Toggle Key Light
# @raycast.author lowply
# @raycast.authorURL https://raycast.com/lowply

DOTFILES_DIR=$(dirname $(dirname $0))
${DOTFILES_DIR}/bin/keylight.sh
