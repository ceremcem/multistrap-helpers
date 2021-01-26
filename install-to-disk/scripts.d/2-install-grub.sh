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

if [[ -z $disk_device ]]; then 
    # probably a loopback device 
    dm=$(readlink -f /dev/disk/by-uuid/${boot_part##UUID=})
    for lo in /dev/mapper/loop*; do
        if [[ "$(readlink -f $lo)" == "$dm" ]]; then
            disk_device=${lo##/dev/mapper/}
            disk_device=${disk_device%p*}
            break
        fi
    done
fi

[[ -z $disk_device ]] && { echo "Can not determine \$disk_device"; exit 1; }
set -x
grub-install /dev/$disk_device --boot-directory=/boot
update-grub # update grub.cfg
