#!/bin/bash
source $APPDIR/config/nginx/vars.sh

# Kill Nginx
if [[ -f $nginx_pid ]]
then
  kill $(cat "$nginx_pid") && echo "killed nginx"
fi
