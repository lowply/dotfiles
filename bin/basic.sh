#!/bin/bash

cat << EOF
# added $(date)
AuthUserFile /home/hogehoge/.htpasswd
AuthGroupFile /dev/null
AuthName "Please enter your ID and password"
AuthType Basic
require valid-user
EOF
