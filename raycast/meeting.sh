#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Start meeting
# @raycast.mode compact

# Optional parameters:
# @raycast.icon 📹

# Documentation:
# @raycast.description Start meeting
# @raycast.author lowply
# @raycast.authorURL https://raycast.com/lowply

$(dirname $(pwd))/bin/keylight.sh
$(dirname $(pwd))/bin/audio-select.sh zoom
open /Applications/zoom.us.app
