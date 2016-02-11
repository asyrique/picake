#!/bin/bash
source $APPDIR/config/nginx/vars.sh

# Launch Nginx
nginx -c "$nginx_conf"
