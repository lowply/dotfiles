#!/bin/bash

set -e

# check argv
#-----------------------------------------

if [ $# -ne 1 ]; then
    echo "usage: $0 <VH_NAME>" 1>&2
    exit 1
fi

HOSTNAME=${1}
DATE=$(date +%c)
WEBDIR="/home/www"
DOCROOT="${WEBDIR}/${HOSTNAME}/htdocs"
LOGDIR="/var/log/nginx/${HOSTNAME}"
CONFFILE="/etc/nginx/conf.d/${HOSTNAME}.conf"

# Check /etc/ssl/dhparam.pem
if [ ! -f /etc/ssl/dhparam.pem ]; then
	echo "/etc/ssl/dhparam.pem not found."
	echo "Please run:"
	echo "openssl dhparam -out /etc/ssl/dhparam.pem 2048"
	exit 1
fi

# Check /etc/ssl/certs/ca-bundle.crt
if [ ! -f /etc/ssl/certs/ca-bundle.crt ]; then
	echo "/etc/ssl/certs/ca-bundle.crt not found."
	exit 1
fi

# config check
if [ -f ${CONFFILE} ]; then
	echo -e "\n${CONFFILE} already exists.\n" 1>&2
	exit 1
fi

if [ ! -d ${WEBDIR} ]; then
    mkdir -p ${WEBDIR}
    chown -R nginx:nginx ${WEBDIR}
	echo "Created ${WEBDIR}"
fi

# make docroot
if [ ! -d ${DOCROOT} ]; then
	mkdir -p ${DOCROOT}
	echo "" > ${DOCROOT}/index.html
	chmod 775 ${DOCROOT}
	chmod g+s ${DOCROOT}
	chown -R nginx:nginx ${DOCROOT}
	echo "Created directory ${DOCROOT}"
else
	echo "${DOCROOT} Already exsits."
fi

# make log dir
if [ ! -d "${LOGDIR}" ]; then
	mkdir ${LOGDIR}
	chown -R nginx:nginx ${LOGDIR}
	echo "Created directory ${LOGDIR}"
else
	echo "${LOGDIR} Already exsits."
fi

# output config
cat << EOF > ${CONFFILE}
#
# added ${DATE}
# ${HOSTNAME}
#

server {
    listen       80;
    listen       [::]:80;
    server_name  ${HOSTNAME};

    # For HTTP-01 challenge
    location ^~ /.well-known/acme-challenge/ {
        root    ${DOCROOT};
        index   index.html;
    }

    location / {
        return 301 https://\$host\$request_uri;
    }
}

server {
    listen       443 ssl http2;
    listen       [::]:443 ssl http2;
    server_name  ${HOSTNAME};

    root         ${DOCROOT};
    index        index.php index.html index.htm;

    ssl_certificate      /etc/nginx/ssl/${HOSTNAME}/cert.pem;
    ssl_certificate_key  /etc/nginx/ssl/${HOSTNAME}/key.pem;

    ssl_session_timeout 1d;
    ssl_session_cache shared:MozSSL:10m;
    ssl_session_tickets off;

    ssl_dhparam /etc/ssl/dhparam.pem;

    ssl_protocols TLSv1.3;
    ssl_prefer_server_ciphers on;
    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-SHA384;

    ssl_stapling on;
    ssl_stapling_verify on;
    ssl_trusted_certificate /etc/ssl/certs/ca-bundle.crt;

    access_log   ${LOGDIR}/access.log main;
    error_log    ${LOGDIR}/error.log warn;

    # client_max_body_size 20M;
    # include basic.conf;
    # include wordpress.conf;
}
EOF

echo "Created ${CONFFILE}. Please restart nginx."
echo "Virtual Host \"${HOSTNAME}\" has been created."
