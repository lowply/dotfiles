#!/bin/bash

. ${HOME}/.bashrc.local
[ -z ${ELGATO_KEYLIGHT_IP} ] && { echo "ELGATO_KEYLIGHT_IP is empty"; exit 1; }
EP="http://${ELGATO_KEYLIGHT_IP}:9123/elgato/lights"
CURRENT_FILE=${HOME}/.kl_current
[ -f ${CURRENT_FILE} ] && CURRENT=$(cat ${CURRENT_FILE})
[ -z ${CURRENT} ] && CURRENT=$(curl -s ${EP})
[ -z ${CURRENT} ] && { echo "Empty output, perhaps failed to connect ${ELGATO_KEYLIGHT_IP}:9123?"; exit 1; }
[ $(echo "${CURRENT}" | jq ".lights[0].on") == 0 ] && TARGET=1 || TARGET=0
curl -s -X PUT -d "$(echo "${CURRENT}" | jq ".lights[0].on|=${TARGET}")" ${EP} > ${CURRENT_FILE}
