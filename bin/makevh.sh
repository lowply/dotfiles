#!/bin/sh

#
# version : 1.20 (2012/07/31)
# - Added Directory directive to SSL VH.
#
# version : 1.10 (2012/07/23)
# - Modified making ssl dir.
#
# version : 1.00 (2012/03/12)
# - First edition.
#

echo ${OSTYPE} | grep "linux" || { echo "Not a Linux OS"; exit 1; }

# check argv
#-----------------------------------------

function usage(){
    echo "usage: $0 -v <VH_NAME> [-s <IPADDR>]"
    exit 1
}

while getopts :v:s: OPT
do
    case $OPT in
    v) ENABLE_v="t";_VH=$OPTARG;;
    s) ENABLE_s="t";_SSLIP=$OPTARG;;
    :|\?) usage;;
    esac
done

_DATE=`date +%c`

# functions
#-----------------------------------------

function make_vh(){

# make docroot

if [ ! -d "/home/$_VH" ]; then
    mkdir -p /home/$_VH/htdocs
    cp -p /var/www/error/noindex.html /home/$_VH/htdocs/index.html
    chmod -R 775 /home/$_VH
    chown -R apache:apache /home/$_VH
    chmod g+s /home/$_VH/htdocs
    echo "Create directory /home/$_VH/htdocs"
else
    echo "/home/$_VH/htdocs Already exsits."
fi

# make log dir

if [ ! -d "/var/log/httpd/$_VH" ]; then
    mkdir /var/log/httpd/$_VH
    echo "Create directory /var/log/httpd/$_VH"
else
    echo "/var/log/httpd/$_VH Already exsits."
fi

# output config

cat << EOF >> /etc/httpd/conf.v/$_VH.conf
# added $_DATE
<VirtualHost *:80>
    ServerName $_VH
    DocumentRoot /home/$_VH/htdocs
    ErrorLog  "|/usr/sbin/rotatelogs /var/log/httpd/$_VH/error_log.%Y%m%d 86400 540"
    CustomLog "|/usr/sbin/rotatelogs /var/log/httpd/$_VH/access_log.%Y%m%d 86400 540" combined
    <Directory /home/$_VH/htdocs>
        DirectoryIndex index.html index.php
        Options FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>
</VirtualHost>
EOF
echo "Create file      /etc/httpd/conf.v/$_VH.conf"
}

function add_ssl(){
_IS_USED=`grep $_SSLIP /etc/httpd/conf.v/*`
if [ -n "$_IS_USED" ]; then
    echo -e "\nThe IP address \"$_SSLIP\" is already used by :"
    echo -e "$_IS_USED\n"
    exit 1
fi

if [ ! -d "/etc/httpd/ssl/" ]; then
    mkdir /etc/httpd/ssl/
fi

if [ ! -d "/etc/httpd/ssl/$_VH" ]; then
    mkdir /etc/httpd/ssl/$_VH
    cd /etc/httpd/ssl/$_VH
    touch ssl.crt ssl.key ca.crt
    chmod 600 ssl.key
fi

cat << EOF >> /etc/httpd/conf.v/$_VH.conf

# added $_DATE
<VirtualHost $_SSLIP:443>
    ServerName $_VH
    DocumentRoot /home/$_VH/htdocs
    ErrorLog  "|/usr/sbin/rotatelogs /var/log/httpd/$_VH/ssl_error_log.%Y%m%d 86400 540"
    CustomLog "|/usr/sbin/rotatelogs /var/log/httpd/$_VH/ssl_access_log.%Y%m%d 86400 540" combined
    CustomLog /var/log/httpd/$_VH/ssl_request_log "%t %h %{SSL_PROTOCOL}x %{SSL_CIPHER}x \"%r\" %b"
    <Directory /home/$_VH/htdocs>
        DirectoryIndex index.html index.php
        Options FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>
    LogLevel warn
    SSLEngine on
    SSLProtocol all -SSLv2
    SSLCipherSuite ALL:!ADH:!EXPORT:!SSLv2:RC4+RSA:+HIGH:+MEDIUM:+LOW
    SSLCertificateFile /etc/httpd/ssl/$_VH/ssl.crt
    SSLCertificateKeyFile /etc/httpd/ssl/$_VH/ssl.key
    SSLCertificateChainFile /etc/httpd/ssl/$_VH/ca.crt
    <Files ~ "\.(cgi|shtml|phtml|php3?)$">
        SSLOptions +StdEnvVars
    </Files>
    SetEnvIf User-Agent ".*MSIE.*" nokeepalive ssl-unclean-shutdown downgrade-1.0 force-response-1.0
</VirtualHost>
EOF
}

# action
#-----------------------------------------

if [ "${ENABLE_v}" != "t" ]; then
    usage
fi

if [ "${ENABLE_s}" != "t" ]; then
    if [ -f /etc/httpd/conf.v/$_VH.conf ]; then
        echo -e "\nVirtual Host \"$_VH\" Already exists. Exit.\n"
        exit 1
    fi
    make_vh
    echo -e "\nThe setting of Virtual Host \"$_VH\" has done. Restart Apache.\n"
else
    if [ -f /etc/httpd/conf.v/$_VH.conf ]; then
        add_ssl
        echo -e "\nVirtual Host \"$_VH\" Already exists. Added SSL directive.\n"
    else
        make_vh
        add_ssl
        echo -e "\nThe setting of Virtual Host \"$_VH\" and SSL has done. Restart Apache.\n"
    fi
fi


