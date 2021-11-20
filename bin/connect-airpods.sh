#!/bin/bash

PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:${PATH}"

abort(){
    >&2 echo "$1"
    exit 1
}

[ -z "$AP_MAC" ] && abort "AP_MAC is missing" # XX-XX-XX-XX-XX-XX
[ -z "$AP_NAME" ] && abort "AP_NAME is missing" # AirPods
[ -z "$SOUND" ] && abort "SOUND is missing" # /path/to/sound.aiff

type BluetoothConnector > /dev/null 2>&1 || abort "BluetoothConnector not found. Run brew install bluetoothconnector"
type SwitchAudioSource > /dev/null 2>&1 || abort "SwitchAudioSource not found. Run brew install switchaudio-osx"

BluetoothConnector -c ${AP_MAC} || abort "Device not found"

for ((i=0 ; i<10 ; i++)); do
    >&2 echo "Waiting for the device... ($i/10)"
    if [ "Connected" == $(BluetoothConnector -s ${AP_MAC}) ]; then
        SwitchAudioSource -s "${AP_NAME}" || abort "Failed to switch"
        afplay "${SOUND}"
        >&2 echo "Connected and switched to ${AP_NAME}!"
        break
    fi
    sleep 1
done
