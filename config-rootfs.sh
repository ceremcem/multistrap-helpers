#!/bin/bash
# From: https://wiki.debian.org/Multistrap#Steps_for_Squeeze_and_later

# run after chrooting into the rootfs
export DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true
export LC_ALL=C LANGUAGE=C LANG=C
/var/lib/dpkg/info/dash.preinst install
dpkg --configure -a
#mount proc -t proc /proc # mounted before do-chroot.sh
#dpkg --configure -a
#umount /proc


apt-get install linux-image-4.9.0-11-amd64 \
	grub2
