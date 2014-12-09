#!/bin/sh

find /var/log/httpd/*/ -name "*_log.????????" -mtime +5 | xargs gzip
