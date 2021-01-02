#!/bin/bash
set -e
if [ "$(stat -c %d:%i /)" != "$(stat -c %d:%i /proc/1/root/.)" ]; then
  echo "Preparing bootable rootfs"
else
  echo "This script is intended to be run in chroot environment!"
  exit 1
fi

apt-get update
apt-get install linux-image-amd64 \
	grub2 \
	systemd \
	initramfs-tools \
	kbd \
    crudini
[[ -e /sbin/init ]] || ln -s /lib/systemd/systemd /sbin/init

# edit initramfs.conf to change KEYMAP=y
crudini --set --inplace /etc/initramfs-tools/initramfs.conf '' KEYMAP y
sed -i -r "s/(\S*)\s*=\s*(.*)/\1=\2/g" /etc/initramfs-tools/initramfs.conf

# Prevent "root account is locked" error:
echo "Create a password for your root account:"
passwd
