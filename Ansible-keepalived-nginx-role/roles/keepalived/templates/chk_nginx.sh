#!/bin/bash
N=`ps -C nginx --no-header|wc -l`
if [ $N -eq 0 ];then
       /usr/local/nginx/sbin/nginx -c /usr/local/nginx/conf/nginx.conf
        sleep 1
        if [ `ps -C nginx --no-header|wc -l` -eq 0 ];then
                killall nginx
        fi
fi
