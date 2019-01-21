#!/bin/bash

. $(dirname $0)/lib.sh

abort(){
    echo "${1}"
    exit 1
}

install(){
    local ACMEPATH="/root/.acme.sh"
    local SSLPATH="/etc/nginx/ssl"
    local DOMAIN=${1}

    [ -f ${ACMEPATH}/${DOMAIN}/fullchain.cer ] || { logger "Missing issued certificate"; return 0; }
    [ -f ${SSLPATH}/${DOMAIN}/cert.pem ] || { logger "Missing current certificate"; return 0; }

    diff -q ${ACMEPATH}/${DOMAIN}/fullchain.cer ${SSLPATH}/${DOMAIN}/cert.pem > /dev/null 2>&1

    if [ $? -eq 0 ]; then
        logger "Certificate isn't updated: ${DOMAIN}"
    else
        logger "Installing certificate and reloading nginx..."
        acme.sh --install-cert -d ${DOMAIN} \
            --key-file ${SSLPATH}/${DOMAIN}/cert.pem \
            --fullchain-file ${SSLPATH}/${DOMAIN}/key.pem \
            --reloadcmd "service nginx force-reload"

        [ $? -eq 0 ] && logger "Installed certificate: ${DOMAIN}" || logger "Failed to install certificate: ${DOMAIN}"
    fi
}

main(){
    check_dir "${HOME}/.acme.sh"
    export PATH=${HOME}/.acme.sh:/usr/sbin:${PATH}

    local CONFIG="${HOME}/.config/le_install.conf"
    autotouchfile ${CONFIG}


    . ${CONFIG}

    [ -z "${AZUREDNS_SUBSCRIPTIONID}" ] && abort "Missing env var in the config: AZUREDNS_SUBSCRIPTIONID"
    [ -z "${AZUREDNS_TENANTID}" ] && abort "Missing env var in the config: AZUREDNS_TENANTID"
    [ -z "${AZUREDNS_APPID}" ] && abort "Missing env var in the config: AZUREDNS_APPID"
    [ -z "${AZUREDNS_CLIENTSECRET}" ] && abort "Missing env var in the config: AZUREDNS_CLIENTSECRET"

    logger "Started installation"

    for domain in ${DOMAINS}
    do
        install ${domain}
    done

    logger "Done installation"
}

main "$@"
