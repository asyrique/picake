#!/bin/bash

# Bash strict mode
set -eu
set -o pipefail
IFS=$'\n\t'

# Umount disk image and umount loop device
umount /srv/builddir/tmpmnt/*
dmsetup --noudevsync remove $BOOTPART
dmsetup --noudevsync remove $ROOTPART

losetup -d $LOOPDEV

exit 0
