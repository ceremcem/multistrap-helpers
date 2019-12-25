#!/bin/bash
set -eu
# From: https://wiki.debian.org/Multistrap#Steps_for_Squeeze_and_later

# run after chrooting into the rootfs
export DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true
export LC_ALL=C LANGUAGE=C LANG=C
dash_preinst="/var/lib/dpkg/info/dash.preinst"
preinst_ok=false
if [[ -f $dash_preinst ]]; then
	$dash_preinst install && preinst_ok=true
fi
dpkg --configure -a
#mount proc -t proc /proc # mounted before do-chroot.sh
#dpkg --configure -a
#umount /proc

# fixes the perl warning
export LANGUAGE=en_US.UTF-8
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
locale-gen en_US.UTF-8
dpkg-reconfigure locales

if [[ "$preinst_ok" = false ]]; then
	echo "WARNING: No $dash_preinst file found,"
	echo "so not executed."
fi
