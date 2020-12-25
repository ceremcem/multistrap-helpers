#!/bin/bash
set -e
if [ "$(stat -c %d:%i /)" != "$(stat -c %d:%i /proc/1/root/.)" ]; then
  echo "Preparing bootable rootfs"
else
  echo "This script is intended to be run in chroot environment!"
  exit 1
fi

boot_part="{{boot_part}}"
disk_device=$(lsblk -no pkname /dev/disk/by-uuid/${boot_part##UUID=})
grub-install $disk_device --boot-directory=/boot
grub-mkconfig -o /boot/grub/grub.cfg

