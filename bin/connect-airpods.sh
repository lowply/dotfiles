#!/bin/bash

PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:${PATH}"

abort(){
    >&2 echo "$1"
    exit 1
}

# To see the UID, run:
# SwitchAudioSource -a -f json
[ -z "${AIRPODS_MAC}" ] && abort "AIRPODS_MAC is missing"
[ -z "${SAS_UID_OUT}" ] && abort "SAS_UID_OUT is missing"
[ -z "${SAS_UID_IN}" ] && abort "SAS_UID_IN is missing"

SOUND=${SOUND:-"${HOME}/Dropbox/Sounds/Funk.aiff"}

type BluetoothConnector > /dev/null 2>&1 || abort "BluetoothConnector not found. Run brew install bluetoothconnector"
type SwitchAudioSource > /dev/null 2>&1 || abort "SwitchAudioSource not found. Run brew install switchaudio-osx"

BluetoothConnector -c ${AIRPODS_MAC} || abort "Device not found"

for ((i=0 ; i<10 ; i++)); do
    >&2 echo "Waiting for the device... ($i/10)"
    if [ "Connected" == $(BluetoothConnector -s ${AIRPODS_MAC}) ]; then
        SwitchAudioSource -t input -u "${SAS_UID_IN}" || abort "Failed to switch"
        SwitchAudioSource -t output -u "${SAS_UID_OUT}" || abort "Failed to switch"
        afplay "${SOUND}"
        AP_NAME=$(SwitchAudioSource -a -f json | jq -r "select(.uid==\"${SAS_UID_OUT}\") | .name")
        >&2 echo "Connected and switched to ${AP_NAME}!"
        break
    fi
    sleep 1
done
