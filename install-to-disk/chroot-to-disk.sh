#!/bin/bash
set -eu

safe_source () { [[ ! -z ${1:-} ]] && source $1; _dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; _sdir=$(dirname "$(readlink -f "$0")"); }; safe_source

safe_source $_sdir/config.sh

# Attach the disk
# ----------------
mkdir -p "$root_mnt" "$rootfs_mnt"
cryptsetup open $crypt_part $crypt_dev_name
lvscan
sleep 2

# in case of automount
umount $boot_part 2> /dev/null || true
umount $root_dev 2> /dev/null || true

mount $root_dev $root_mnt # for subvolume operations
mount -t btrfs -o subvol=$subvol $root_dev $rootfs_mnt

# mount boot partition
mkdir -p $rootfs_mnt/boot
mount $boot_part $rootfs_mnt/boot

# chroot
./do-chroot.sh $rootfs_mnt

# detach
$_sdir/detach-disk.sh
