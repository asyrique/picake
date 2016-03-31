#!/bin/bash

# Bash strict mode
set -euv
IFS=$'\n\t'

APPDIR=/srv/app

echo "HERE BE $DIR"
echo -e "\e[1;32mchrooted into Arch system\e[0m"
echo
echo -e "\e[1;32mRunning pacman update\e[0m"
pacman -Sy
echo -e "\e[1;32mInstalling base for wifi and DHCP\e[0m"
pacman -S --noconfirm crda \
                      iw \
                      sudo \
                      vim \
                      python2 \
                      wireless-regdb \
                      wpa_supplicant \
                      bind \
                      hostapd \
                      dhcp \
                      git \
                      wget \
                      curl ca-certificates-mozilla db dbus ncurses openresolv openssl xfsprogs \
                      unzip

echo -e "\e[1;32mListing of host filesystem\e[0m"
echo -e "\e[1;32m====================================================\e[0m"
echo
ls -al /host-rootfs$DIR/src
echo -e "\e[1;32mInstalling kernel\e[0m"
pacman -U --noconfirm /host-rootfs$DIR/src/kernel/linux-raspberrypi-4.1.20-3-armv7h.pkg.tar.xz /host-rootfs$DIR/src/kernel/linux-raspberrypi-headers-4.1.20-3-armv7h.pkg.tar.xz
mkdir $APPDIR
cp -r /host-rootfs$DIR/src/config $APPDIR
cp -r /host-rootfs$DIR/src/scripts $APPDIR
cp -r /host-rootfs$DIR/src/deps $APPDIR

if [ ! -z ${PRIV_KEY:-} ]
then
  echo -e "\e[1;32mInstall private key\e[0m"
  mkdir -p /root/.ssh /home/alarm/.ssh
  echo $PRIV_KEY > /root/.ssh/id_rsa
  echo $PRIV_KEY > /home/alarm/.ssh/id_rsa
  chmod 600 /root/.ssh/id_rsa /home/alarm/.ssh/id_rsa
  chown alarm:alarm /home/alarm/.ssh/id_rsa
fi

echo -e "\e[1;32mRunning scripts in install.d\e[0m"
# Put scripts to install in the install.d directory
for SCRIPT in /host-rootfs$DIR/src/scripts/install.d/*
  do
    if [ -f $SCRIPT -a -x $SCRIPT ]
    then
      echo -e "\e[1;32mInstalling $(basename $SCRIPT)\e[0m"
      . $SCRIPT
    fi
done
echo -e "\e[1;32mCopying service files to systemd directory \e[0m"
cp $APPDIR/scripts/picake.service /etc/systemd/system/
echo -e "\e[1;32mCreating env variables\e[0m"
mkdir /etc/systemd/system/picake.service.d
cat << EOF > /etc/systemd/system/picake.service.d/env.conf
[Service]
Environment="APPDIR=$APPDIR"
EOF
echo -e "\e[1;32mEnabling Pi-Platform service manually\e[0m"
ln -s /etc/systemd/system/picake.service /etc/systemd/system/multi-user.target.wants/picake.service
exit 0
