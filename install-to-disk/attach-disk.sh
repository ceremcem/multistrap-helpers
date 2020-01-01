#!/bin/bash
set -eu

safe_source () { [[ ! -z ${1:-} ]] && source $1; _dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; _sdir=$(dirname "$(readlink -f "$0")"); }; safe_source

safe_source $_sdir/config.sh

function echo_and_run {
  echo "$@"
  eval $(printf '%q ' "$@") < /dev/tty
}

[[ $(whoami) = "root" ]] || { sudo "$0" "$@"; exit 0; }

# Attach the disk
# ----------------
mkdir -p "$root_mnt" "$rootfs_mnt"
cryptsetup open $crypt_part $crypt_dev_name
lvscan
sleep 2

# in case of automount
umount $boot_part 2> /dev/null || true
umount $root_dev 2> /dev/null || true

set +e
mount $root_dev $root_mnt # for subvolume operations
if [[ $? -ne 0 ]]; then
    cat << EOL

Mounting $root_dev failed. If this device had a RAID-1
configuration and the failure is because of a missing device,
you may try to mount the partition Readonly by the following
command:

	mount -t btrfs -o ro,degraded $root_dev $root_mnt

EOL
    exit
fi
set -e

[[ -d $root_mnt/$subvol ]] || btrfs sub create $root_mnt/$subvol
mount -t btrfs -o subvol=$subvol $root_dev $rootfs_mnt

# mount boot partition
mkdir -p $rootfs_mnt/boot
mount $boot_part $rootfs_mnt/boot

