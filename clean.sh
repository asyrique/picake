#!/bin/bash

# Umount disk image and umount loop device
umount /srv/builddir/tmpmnt/*
for part in $(dmsetup ls | awk '{print $1}'); do
    if dmsetup --noudevsync remove $part ; then
      echo -e "\e[1;32m$part detached\e[0m"
    fi
done

for loopdev in $(losetup -a | awk '{print $1}' | sed 's/.$//'); do
  # loopback dev may be tied up a bit by udev events triggered by partition events
  for try in {10..1..-1} ; do
    if losetup -d $loopdev ; then
      echo -e "\e[1;32m$loopdev detached\e[0m"
      break
    fi
    if [ $try -eq 0 ]; then
      echo -e "\e[1;31mGave up trying to detach $loopdev\e[0m"
      exit 1
    fi
    echo "\e[1;33m$loopdev may be busy, sleeping up to $try more seconds...\e[0m"
    sleep 1
  done
done

exit 0
