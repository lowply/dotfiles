#!/bin/bash

[ -z ${ELGATO_KEYLIGHT_IP} ] && { echo "ELGATO_KEYLIGHT_IP is empty"; exit 1; }
EP="http://${ELGATO_KEYLIGHT_IP}:9123/elgato/lights"
CURRENT=$(curl -s ${EP})
[ $(echo "${CURRENT}" | jq ".lights[0].on") == 0 ] && TARGET=1 || TARGET=0
curl -s -X PUT -d "$(echo "${CURRENT}" | jq ".lights[0].on|=${TARGET}")" ${EP}
