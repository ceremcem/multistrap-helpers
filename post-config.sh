#!/bin/bash
set -eu
# From: https://wiki.debian.org/Multistrap#Steps_for_Squeeze_and_later

# run after chrooting into the rootfs
export DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true
export LC_ALL=C LANGUAGE=C LANG=C
dash_preinst="/var/lib/dpkg/info/dash.preinst"
if [[ -f $dash_preinst ]]; then
	$dash_preinst install
else
	# See https://unix.stackexchange.com/a/558868/65781
	echo "No $dash_preinst found, skipping."
fi
dpkg --configure -a

unset DEBIAN_FRONTEND DEBCONF_NONINTERACTIVE_SEEN


# fixes the perl warning
export LANGUAGE=en_US.UTF-8
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
locale-gen en_US.UTF-8
dpkg-reconfigure locales
