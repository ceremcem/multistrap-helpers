#!/bin/bash
set -eu

safe_source () { [[ ! -z ${1:-} ]] && source $1; _dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; _sdir=$(dirname "$(readlink -f "$0")"); }; safe_source

config_file=${1:-}
[[ ! -f $config_file ]] && { echo "Usage: $(basename $0) path/to/config-file"; exit 1; }
safe_source $config_file

function echo_and_run {
  echo "$@"
  eval $(printf '%q ' "$@") < /dev/tty
}

[[ $(whoami) = "root" ]] || { sudo "$0" "$@"; exit 0; }

# Attach the disk
# ----------------
if [[ -n ${image_file:-} ]]; then
	[[ ! -f $image_file ]] && { echo "Can not find image file: $image_file"; exit 1; }
	echo "Found image, associating relevant loopback devices:"
	kpartx -av $image_file
fi

mkdir -p "$root_mnt" "$rootfs_mnt"
__use_key=
[[ -n ${crypt_key:-} ]] && __use_key="--key-file=$crypt_key"
cryptsetup open $crypt_part $crypt_dev_name $__use_key
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

if [[ ! -d $root_mnt/$subvol ]]; then
	echo "$root_mnt/$subvol is required, automatically creating."
	btrfs sub create $root_mnt/$subvol
fi
mount -t btrfs -o subvol=$subvol $root_dev $rootfs_mnt

# mount boot partition
mkdir -p $rootfs_mnt/boot
mount $boot_part $rootfs_mnt/boot

