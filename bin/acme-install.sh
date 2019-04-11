#!/bin/bash

. $(dirname $0)/lib.sh

install(){
    local DOMAIN=${1}
    local SSLPATH="/etc/nginx/ssl"
    [ -d ${SSLPATH}/${DOMAIN} ] || mkdir ${SSLPATH}/${DOMAIN}

    [ -f ${ACMEDIR}/${DOMAIN}/fullchain.cer ] || {
        logger "Missing issued certificate: ${DOMAIN}"
        return 0
    }

    [ -f ${SSLPATH}/${DOMAIN}/cert.pem ] && {
        diff -q ${ACMEDIR}/${DOMAIN}/fullchain.cer ${SSLPATH}/${DOMAIN}/cert.pem > /dev/null 2>&1 && {
            # Certificate isn't updated, silently skip the installation
            return 0
        }
    }

    logger "Installing certificate and reloading nginx..."

    ${ACMEDIR}/acme.sh --install-cert -d ${DOMAIN} \
        --key-file ${SSLPATH}/${DOMAIN}/key.pem \
        --fullchain-file ${SSLPATH}/${DOMAIN}/cert.pem \
        --reloadcmd "systemctl reload nginx"

    if [ $? -eq 0 ]; then
        message success "Installed certificate: ${DOMAIN}"
        return 0
    else
        message error "Failed to install certificate: ${DOMAIN}"
        return 1
    fi
}

main(){
    [ "$(whoami)" == "root" ] || abort "This command should be run by root."
    [ $# -eq 1 ] || abort "Usage: acme-install.sh /path/to/.acme.sh"

    ACMEDIR="${1}"
    check_dir "${ACMEDIR}"

    CONFIGS=$(ls -1 /etc/nginx/conf.d/ | sed -e 's/\.conf//g')

    for DOMAIN in ${CONFIGS}
    do
        [ -d ${ACMEDIR}/${DOMAIN} ] || continue
        logger "Started installation for ${DOMAIN}"
        install ${DOMAIN}
    done

    logger "Done installation"
}

main "$@"
