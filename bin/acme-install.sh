#!/bin/bash

#
# Use this in a crontab, like this:
# 0 6 * * * LE_WORKING_DIR="/path/to/.acme.sh" ${HOME}/.ghq/github.com/lowply/dotfiles/bin/acme-install.sh > /dev/null
#

. $(dirname $0)/lib.sh

install(){
    local DOMAIN=${1}
    local SSLPATH="/etc/nginx/ssl"
    [ -d ${SSLPATH}/${DOMAIN} ] || mkdir ${SSLPATH}/${DOMAIN}

    [ -f ${LE_WORKING_DIR}/${DOMAIN}/fullchain.cer ] || {
        logger "Missing issued certificate: ${DOMAIN}"
        return 0
    }

    [ -f ${SSLPATH}/${DOMAIN}/cert.pem ] && {
        diff -q ${LE_WORKING_DIR}/${DOMAIN}/fullchain.cer ${SSLPATH}/${DOMAIN}/cert.pem > /dev/null 2>&1 && {
            # Certificate isn't updated, silently skip the installation
            return 0
        }
    }

    logger "Installing certificate and reloading nginx..."

    ${LE_WORKING_DIR}/acme.sh --install-cert -d ${DOMAIN} \
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
    [ -z "$LE_WORKING_DIR" ] && abort "LE_WORKING_DIR is empty"
    check_dir "${LE_WORKING_DIR}"

    CONFIGS=$(ls -1 /etc/nginx/conf.d/ | sed -e 's/\.conf//g')

    for DOMAIN in ${CONFIGS}
    do
        [ -d ${LE_WORKING_DIR}/${DOMAIN} ] || continue
        logger "Started installation for ${DOMAIN}"
        install ${DOMAIN}
    done

    logger "Done installation"
}

main "$@"
