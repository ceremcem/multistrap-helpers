#!/bin/bash

if [ "$(stat -c %d:%i /)" != "$(stat -c %d:%i /proc/1/root/.)" ]; then
  echo "Preparing bootable rootfs"
else
  echo "This script is intended to be run in chroot environment!"
  exit 1
fi

apt-get install linux-image-4.9.0-11-amd64 \
	grub2 \
	systemd
ln -s /lib/systemd/systemd /sbin/init
