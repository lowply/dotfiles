#!/bin/bash

#
# version : 1.00 (2014/03/18 sho@fixture.jp)
# - First edition.
#

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
    v) ENABLE_v="t";_VH=$OPTARG;;
    :|\?) usage;;
    esac
done

shift `expr ${OPTIND} - 1`

_DATE=`date +%c`

# functions
#-----------------------------------------

function make_vh(){

# config check
if [ -f /etc/nginx/conf.d/$_VH.conf ]; then
    echo -e "\nVirtual Host \"$_VH\" Already exists. Exit.\n"
    exit 1
fi

# make docroot

if [ ! -d "/home/$_VH" ]; then
    mkdir -p /home/$_VH/htdocs
	echo $_VH > /home/$_VH/htdocs/index.html
    chmod 775 /home/$_VH
    chown -R nginx:nginx /home/$_VH
    echo "Create directory /home/$_VH/htdocs"
else
    echo "/home/$_VH/htdocs Already exsits."
fi

# make log dir

if [ ! -d "/var/log/nginx/$_VH" ]; then
    mkdir /var/log/nginx/$_VH
    echo "Create directory /var/log/nginx/$_VH"
else
    echo "/var/log/nginx/$_VH Already exsits."
fi

# output config

cat << EOF >> /etc/nginx/conf.d/$_VH.conf
# added $_DATE
server {
    listen      unix:/var/run/nginx-backend.sock;
    server_name $_VH;
    root        /home/$_VH/htdocs;
    index       index.php index.html index.htm;

    access_log  /var/log/nginx/${_VH}/backend.access.log backend;
    error_log   /var/log/nginx/${_VH}/backend.error.log;

    keepalive_timeout 25;
    port_in_redirect  off;

    gzip              off;
    gzip_vary         off;

    include /etc/nginx/wp-singlesite;
    #include /etc/nginx/wp-multisite-subdir;
}

server {
    listen      80;
    server_name $_VH;
    root        /home/$_VH/htdocs;
    index       index.html index.htm;
    charset     utf-8;

    access_log  /var/log/nginx/${_VH}/access.log  main;
    error_log   /var/log/nginx/${_VH}/error.log;

    include     /etc/nginx/drop;

    rewrite /wp-admin$ \$scheme://\$host\$uri/ permanent;
    #rewrite ^(.*)(index|home|default)\.html? \$1 permanent;

    set \$mobile '';
    #include /etc/nginx/mobile-detect;

    location ~* ^/wp-(content|admin|includes) {
        index   index.php index.html index.htm;
        if (\$request_filename ~ .*\.php) {
            break;
            proxy_pass http://backend;
        }
        include /etc/nginx/expires;
    }

    #location ~* \.(js|css|html?|xml|gz|jpe?g|gif|png|swf|wmv|flv|ico)$ {
    #    index   index.html index.htm;
    #    include /etc/nginx/expires;
    #}

    location / {
        if (\$request_filename ~ .*\.php) {
            break;
            proxy_pass http://backend;
        }
        include /etc/nginx/expires;

        set \$do_not_cache 0;
        if (\$http_cookie ~* "comment_author_|wordpress_(?!test_cookie)|wp-postpass_" ) {
            set \$do_not_cache 1;
        }
        if (\$request_method = POST) {
            set \$do_not_cache 1;
        }
        proxy_no_cache     \$do_not_cache;
        proxy_cache_bypass \$do_not_cache;

        proxy_redirect     off;
        proxy_cache        czone;
        proxy_cache_key    "\$scheme://\$host\$request_uri\$mobile";
        proxy_cache_valid  200 0m;
        proxy_pass http://backend;
    }

    #
    # When you use phpMyAdmin, uncomment the line "include /etc/nginx/phpmyadmin;"
    # and delete or comment out the below line "location ~* /(phpmyadmin|myadmin|pma) { }".
    #
    ##include     /etc/nginx/phpmyadmin;
    location ~* /(phpmyadmin|myadmin|pma) {
        access_log off;
        log_not_found off;
        return 404;
    }

    #
    # redirect server error pages to the static page /50x.html
    #
    error_page   500 502 503 504  /50x.html;
    location = /50x.html {
        root   /usr/share/nginx/html;
    }
}
EOF
echo "Create /etc/nginx/conf.d/$_VH.conf"
echo -e "\nThe setting of Virtual Host \"$_VH\" has done. Restart nginx.\n"
}


# action
#-----------------------------------------

if [ "${ENABLE_v}" != "t" ]; then
	usage
fi

make_vh

