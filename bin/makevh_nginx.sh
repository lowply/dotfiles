#!/bin/bash

PATH=/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin
export PATH

# check argv
#-----------------------------------------

function usage(){
    echo "usage: $0 -v <VH_NAME>" 1>&2
    exit 1
}

while getopts :v: OPT
do
    case $OPT in
    v) ENABLE_v="t";HOSTNAME=$OPTARG;;
    :|\?) usage;;
    esac
done

shift `expr ${OPTIND} - 1`

# functions
#-----------------------------------------

function make_vh(){
	local DATE=`date +%c`
	local DOCROOT="/home/www/${HOSTNAME}"
	local LOGDIR="/var/log/nginx/${HOSTNAME}"
	local CONFFILE="/etc/nginx/conf.d/${HOSTNAME}.conf"

	# config check
	if [ -f /etc/nginx/conf.d/${HOSTNAME}.conf ]; then
		echo -e "\nVirtual Host \"${HOSTNAME}\" Already exists. Exit.\n"
		exit 1
	fi

	# make docroot
	if [ ! -d "${DOCROOT}" ]; then
		mkdir -p ${DOCROOT}/htdocs
		echo "" > ${DOCROOT}/htdocs/index.html
		chmod 775 ${DOCROOT}
		chown -R nginx:nginx ${DOCROOT}
		echo "Create directory ${DOCROOT}/htdocs"
	else
		echo "${DOCROOT} Already exsits."
	fi

	# make log dir
	if [ ! -d "${LOGDIR}" ]; then
		mkdir ${LOGDIR}
		chown -R nginx:nginx ${LOGDIR}
		echo "Create directory ${LOGDIR}"
	else
		echo "${LOGDIR} Already exsits."
	fi

	# output config
	cat <<- EOF > ${CONFFILE}
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
	echo "Create ${CONFFILE}"
	echo -e "\nThe setting of Virtual Host \"${HOSTNAME}\" has done. Restart nginx.\n"
}


# action
#-----------------------------------------

if [ "${ENABLE_v}" != "t" ]; then
	usage
fi

make_vh

