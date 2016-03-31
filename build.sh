#!/bin/bash

# Bash strict mode
set -euv
IFS=$'\n\t'

# Get script directory
export DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo -e "\e[1;32mCurrent directory is $DIR\e[0m"
# Create directories for image build
echo -e "\e[1;32mCreating build directories\e[0m"
mkdir -p /srv/builddir
mkdir -p /srv/builddir/src /srv/builddir/img /srv/builddir/tmpmnt
mkdir -p /srv/builddir/tmpmnt/boot /srv/builddir/tmpmnt/root

# Download latest Arch ARM image to builddir
echo -e "\e[1;32mStarted downloading Arch image\e[0m"
wget -q http://archlinuxarm.org/os/ArchLinuxARM-rpi-2-latest.tar.gz -O /srv/builddir/src/ArchLinuxARM-rpi-2-latest.tar.gz
if [ $? -eq 0 ]; then
  echo -e "\e[1;32mGot arch image\e[0m"
else
  echo -e "\e[1;31mArch image download failed\e[0m"
fi

# Allocate build image
echo -e "\e[1;32mStarted allocate disk image\e[0m"
# truncate is only tested on Ubuntu 14.04. Please replace with the correct command for your distro
truncate -s 5G /srv/builddir/img/rpi2-picake.img
echo -e "\e[1;32mDisk image created at /srv/builddir/img/rpi2-picake.img\e[0m"

# Begin partitioning disk image.
# Creating two partitions:
# BOOT = 100 MB
# ROOT = 5900 MB
fdisk /srv/builddir/img/rpi2-picake.img <<EOF
o
n
p
1

+100M

t
c
n
p
2


w
EOF

# Create a loop device and mount the disk image
export LOOPDEV="$(losetup --show --find /srv/builddir/img/rpi2-picake.img)"
echo -e "\e[1;32mLoop device is ${LOOPDEV}\e[0m"

# Use kpartx to create partitions in /dev/mapper
kpartx -av $LOOPDEV
dmsetup --noudevsync mknodes

# Create partition names to mount
export BOOTPART=$(echo $LOOPDEV | sed 's|'/dev'/|'/dev/mapper/'|')p1
export ROOTPART=$(echo $LOOPDEV | sed 's|'/dev'/|'/dev/mapper/'|')p2

# Create filesystems for the partitions
mkfs.vfat $BOOTPART
mkfs.ext4 $ROOTPART

# Mount filesystems in tmpmnt
mount $BOOTPART -t vfat /srv/builddir/tmpmnt/boot
mount $ROOTPART -t ext4 /srv/builddir/tmpmnt/root

# Extract all the files to the image root
bsdtar -xpf /srv/builddir/src/ArchLinuxARM-rpi-2-latest.tar.gz -C /srv/builddir/tmpmnt/root
sync
mv /srv/builddir/tmpmnt/root/boot/* /srv/builddir/tmpmnt/boot/

# Mount proot and run commands inside
proot -q qemu-arm-static -S /srv/builddir/tmpmnt/root -b /srv/builddir/tmpmnt/boot:/boot /bin/bash < $DIR/src/config/env <<EOF
source /host-rootfs$DIR/src/scripts/arch-build.sh
EOF
sync
exit 0
