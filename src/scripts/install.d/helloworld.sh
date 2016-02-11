#!/bin/bash

# Install software from pacman
pacman -S --noconfirm --needed nginx
sed -i'' 's|$APPDIR|'$APPDIR'|g' $APPDIR/config/nginx/nginx.conf

# Setup instructions
mkdir -p $APPDIR/web
echo -e "\e[1;32mCopying files over\e[0m"
cp -R $APPDIR/deps/helloworld/* $APPDIR/web
chown -R http:http $APPDIR/web
echo -e "\e[1;32mDone\e[0m"
