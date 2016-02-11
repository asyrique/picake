FROM ubuntu:14.04
MAINTAINER asyrique@gmail.com
RUN apt-get update
RUN apt-get install -y software-properties-common
RUN add-apt-repository ppa:jacob/virtualisation -y && apt-get update
RUN apt-get install -y bsdtar kpartx qemu-user-static haveged libtalloc2 dosfstools pigz wget make
RUN mkdir -p /srv/builddir
RUN mkdir -p /srv/builddir/src
RUN wget -q http://download.opensuse.org/repositories/home:/cedric-vincent/xUbuntu_14.04/amd64/proot_5.1.0-1_amd64.deb -O /srv/builddir/src/proot_5.1.0-1_amd64.deb
RUN dpkg -i /srv/builddir/src/proot_5.1.0-1_amd64.deb
