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
DOCROOT="/home/www/${HOSTNAME}"
LOGDIR="/var/log/nginx/${HOSTNAME}"
CONFFILE="/etc/nginx/conf.d/${HOSTNAME}.conf"

# config check
if [ -f ${CONFFILE} ]; then
	echo -e "\n${CONFFILE} already exists.\n" 1>&2
	exit 1
fi

# make docroot
if [ ! -d "${DOCROOT}" ]; then
	mkdir -p ${DOCROOT}/htdocs
	echo "" > ${DOCROOT}/htdocs/index.html
	chmod 775 ${DOCROOT}
	chown -R nginx:nginx ${DOCROOT}
	chmod g+s ${DOCROOT}
	echo "Created directory ${DOCROOT}/htdocs"
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
	server_name  ${HOSTNAME};
	root         ${DOCROOT}/htdocs;
	index        index.php index.html index.htm;

	access_log   ${LOGDIR}/access.log  main;
	error_log    ${LOGDIR}/error.log  warn;

	include basic.conf;
	#include wordpress.conf;
}
EOF
echo "Created ${CONFFILE}. Please restart nginx."

echo -e "\nVirtual Host \"${HOSTNAME}\" has created.\n"
