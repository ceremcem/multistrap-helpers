#!/bin/bash
set -eu

safe_source () { [[ ! -z ${1:-} ]] && source $1; _dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; _sdir=$(dirname "$(readlink -f "$0")"); }; safe_source

die(){ echo "$@"; exit 1; }

[[ $(whoami) = "root" ]] || { sudo "$0" "$@"; exit 0; }
config_file=${1:-}
[[ -n $config_file && -f $config_file ]] \
    && config_file=$(realpath $config_file) \
    || die "Configuration file is required." 
cd "$(dirname "$config_file")"
. $config_file

function echo_and_run {
  echo "$@"
  eval $(printf '%q ' "$@") < /dev/tty
}

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
echo "Mounting $root_dev"
mount $root_dev $root_mnt -o ${mount_opts:-noatime}
if [[ $? -ne 0 ]]; then
    cat << EOL

$(basename $0): Mounting $root_dev failed. If this device had a RAID-1
configuration and the failure is because of a missing device,
you may try to mount the partition Readonly by the following
command:

	mount -t btrfs -o ro,degraded,noatime $root_dev $root_mnt

EOL
    exit
fi
set -e

echo "$lvm_name is attached. ($root_mnt)"
# All done. 
