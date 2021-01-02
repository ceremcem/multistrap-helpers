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

if mountpoint $root_mnt &> /dev/null; then
    echo "Seems already attached. Doing nothing."
    exit 0
fi
echo "Mounting $root_dev"

__use_key=
[[ -n ${crypt_key:-} ]] && __use_key="--key-file=$crypt_key"
cryptsetup open $crypt_part $crypt_dev_name $__use_key
while sleep 1; do 
  lvscan | grep ACTIVE | grep $lvm_name && break
done

mkdir -p "$root_mnt"

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

echo "$lvm_name is attached. ($root_mnt)"
# All done. 
