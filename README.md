### piCake (π:cake:) [![Build Status](https://travis-ci.org/asyrique/picake.svg?branch=master)](https://travis-ci.org/asyrique/picake)

An image builder and Arch base image for RPi 2 that can be extended to build images with preinstalled configs and packages.

# Rationale
Building pre-built images is hard. The curent status quo is setting up the image on your device and then using `dd` to create the device image.

# Structure
All app files live in the `/srv` directory.

# Build process
### build.sh
1. Build directories are set up as below:
```
/srv/ ->
  - src/ # All sources are downloaded/cloned into this directory
  - img/ # The final image "rpi2-picake.img" lives in this directory
  - tmpmnt/ ->
    - boot # The boot partition of the image is mounted to this directory
    - root # The root partition of the image is mounted to this directory
```
1. The latest Arch Arm image for the RPi 2 is downloaded into `/srv/builddir/src/ArchLinuxARM-rpi-2-latest.tar.gz`.

1. The final disk image is allocated at `/srv/builddir/img/rpi2-picake.img`. (Note: The default size of 3G is specified in `build.sh`. This is an arbitrary size that is an artefact of piCake's original use-case.)

1. fdisk is used with a bash HEREDOC to partition the .img file into a 100MB root partition and a [size of image file - 100]MB root partition.
(Note: The empty lines in the bash HEREDOC passed to fdisk are INTENTIONAL as they pass a /newline to accept the FDISK default.)

1. A loop device is created (this is why the --privileged flag is required on the docker container) and pointed at the rpi2-picake.img file. We save the loopdevice in the $LOOPDEV bash variable.

1. `kpartx` is used to detect partitions from the loop device and create devices in `/dev/mapper`. `dmsetup` is then used to the prepare the devices for mounting. The --noudevsync tag is used because docker containers don't have access to udev.

1. We format and create the filesystems in `/dev/mapper` with FAT32 for the `boot` parttion and EXT4 for the `root` partition.

1. Then, we mount the `boot` partition at `/srv/buiddir/tmpmnt/boot` and the `root` partition at `/srv/buiddir/tmpmnt/root`.

1. We use `bsdtar` (to preserve permissions) to extract the contents of the downloaded arch image into `/srv/buiddir/tmpmnt/root`. Then,  we move the contents of `/srv/buiddir/tmpmnt/root/boot` to `/srv/buiddir/tmpmnt/boot` to ensure that the boot files are allocated properly.

1. We use `proot` to chroot into the image, passing in the boot and root partitions mounted in `/srv/builddir/tmpmnt` as parameters. `proot` is syntatic sugar as it mounts the dns configuration and the `/proc` and `/dev` directories among others. It also conveniently mounts the host fs at `/host-rootfs` in the chroot. However, it is also perfectly legit to rewrite this to use vanilla chroot.

1. We `source` the env file at `./src/config/env` in order to pass variables defined in the current Bash shell to the Bash shell invoked by `proot`. This is a bit of a hack, but I haven't found a better way so far. Then we `source`

### arch-build.sh
1. We define `$APPDIR` at the top of this file. By default it is `/srv/app`.

1. We run `pacman -Syu` to pull in a couple of base packages. Currently we pull in:
  - `crda, iw, wireless-regdb, wpa_supplicant` for Wifi
  - `vim, sudo, python2, wget, git, curl, ca-certificates-mozilla, db, dbus,  ncurses, openresolv, openssl, xfsprogs, unzip` for general utility, updating ssh and easy of use when SSH-ing into the Pi.
  - `bind` to provide the on-box DNS for the self-hosted Wifi hotspot.
  - `hostapd` to create the self-hosted wifi network
  - `dhcp` to provide dhcp address assignment on the self-hosted wifi network.

1. We install a custom-built kernel from `./src/kernel/linux-raspberrypi-4.1.15-1-armv7h.pkg.tar.xz`. This custom-build of the kernel includes a wifi patch that enables the rt2x00 wifi card to host multiple wifi networks i.e. to host a wifi network while being a client to another wifi network. This is NOT REQUIRED if you do not need virtual wifi capability. If you choose to comment this line out though, you MUST update the `hostapd` config files to point to the correct device.

1. We copy `./src/config`, `./src/deps` and `./src/scripts`.

1. If you have a public key defined in the `$PRIV_KEY` env variable, it will be inserted in `/root/.ssh/id_rsa` and `/home/alarm/.ssh/id_rsa`.

1. Now, we will execute the **executable** scripts in `./src/scripts/install.d` by `source`ing them into the current script. Currently, there are NO guarantees about the order in which the scripts are run.

1. Now, we copy the systemd init files to `/etc/systemd/system` and create an env config file in `/etc/systemd/system/picake.service.d`. We copy the `$APPDIR` variable into here to enable changing the APPDIR in one location only (at the top of `arch-build.sh`). The symbolic links duplicate what happens when `systemctl enable <service>` is run as systemd detects when it is in a chroot environment and does not run, thus `systemctl` does not work.

### clean.sh
1. We try to detach all devices listed by `dmsetup ls`. Currently this detaches **ALL** devices, not just the two used by the current build. This is because I have yet to figure out how to share the `$BOOTPART` and `$ROOTPART` variables to the `clean.sh` script. This is due to Drone's build process running each script in a new Bash shell.

1. The loop device is also removed using `losetup -d`.

### deploy.sh
1. We use `pigz` which is a version of gzip optimized to utilize multiple cores to gzip up the image.

1. The image is then deployed to the release directory, in this case `/host-release` which is mounted from `/srv/app/releases/picake`.

# Keeping your fork in sync

If you fork this repository, but want to keep it in sync with updates pushed to the master, don't forget to add this repo as an `upstream` branch to your current fork. Instructions here: https://help.github.com/articles/configuring-a-remote-for-a-fork/

Then, you can sync your fork at any time like so:
https://help.github.com/articles/syncing-a-fork/

# TODO
- [ ] Command-line client to build images.
- [ ] Investigate removing dependency on Drone
- [ ] Save $BOOTPART and $ROOTPART to a temporary build file to remove only the relevant devices in `clean.sh`.
- [ ] Make fdisk commands more explicit i.e. don't accept defaults, specify all values.
- [ ] Move to Alpine Linux for the build container.
- [ ] Consider Alpine as a base for the RPi base.

# License
[Here](https://github.com/asyrique/picake/blob/master/LICENSE)

Code originally by Asyrique Thevendran, 2016.
Heavily inspired by [this blog post](https://lionfacelemonface.wordpress.com/2015/04/18/raspberry-pi-build-environment-in-no-time-at-all/)

Name credits: My brother, Aqiel Thevendran.
