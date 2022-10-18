#!/bin/bash

PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:${PATH}"

abort(){
    >&2 echo "$1"
    exit 1
}

usage(){
    abort "Usage: ./audio-select.sh <MODE>"
}

connect_bt(){
    local MAC=${1}

    BT_STATUS=$(BluetoothConnector -s ${MAC})

    if [ "${BT_STATUS}" == "Disconnected" ]; then
        timeout 3 BluetoothConnector -c ${MAC}
        [ $? -ne 0 ] && abort "Failed to connect ${MAC} in less than 3 seconds."
    elif [ "${BT_STATUS}" == "Connected" ]; then
        echo "${MAC} is already connected."
    else
        abort "${MAC} not found, or something is wrong."
    fi
}

select_audio(){
    local INPUT=${1}
    local OUTPUT=${2}

    AUDIO_SWITCH_SOUND=${AUDIO_SWITCH_SOUND:-"${HOME}/Dropbox/Sounds/Funk.aiff"}

    SwitchAudioSource -t input -u "${INPUT}" > /dev/null || abort "Failed to switch input"
    SwitchAudioSource -t output -u "${OUTPUT}" > /dev/null || abort "Failed to switch output"

    afplay "${AUDIO_SWITCH_SOUND}"
    INPUT_NAME=$(SwitchAudioSource -a -f json | jq -r "select(.uid==\"${INPUT}\" and .type==\"input\") | .name")
    OUTPUT_NAME=$(SwitchAudioSource -a -f json | jq -r "select(.uid==\"${OUTPUT}\" and .type==\"output\") | .name")
    echo "Input set to ${INPUT_NAME}, Output set to ${OUTPUT_NAME}"
}

type BluetoothConnector > /dev/null 2>&1 || abort "BluetoothConnector not found. Run brew install bluetoothconnector"
type SwitchAudioSource > /dev/null 2>&1 || abort "SwitchAudioSource not found. Run brew install switchaudio-osx"

[ $# -eq 1 ] || usage 

MODE=${1}
UID_AP="34-31-8F-54-3C-93:output"
UID_M4="com_motu_driver_coreuac_control_interface:m4ae1e35ej"

case ${MODE} in
    "zoom")
        connect_bt "${UID_AP/:output/}"
        select_audio "${UID_M4}" "${UID_AP}"
        ;;
    "music")
        select_audio "${UID_M4}" "${UID_M4}"
        ;;
    *)
        echo "No such mode: ${MODE}"
        exit 1
        ;;
esac
