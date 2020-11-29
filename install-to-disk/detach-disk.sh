#!/bin/bash
set -eu

safe_source () { [[ ! -z ${1:-} ]] && source $1; _dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; _sdir=$(dirname "$(readlink -f "$0")"); }; safe_source

function echo_and_run {
  echo "$@"
  eval $(printf '%q ' "$@") < /dev/tty
}

config_file=${1:-}
[[ ! -f $config_file ]] && { echo "Usage: $(basename $0) path/to/config-file"; exit 1; }
safe_source $config_file

[[ $(whoami) = "root" ]] || { sudo "$0" "$@"; exit 0; }

echo "Detaching ${lvm_name}..."
boot_part_dev=$(blkid | grep ${boot_part##UUID=} | cut -d: -f1)
echo_and_run umount $boot_part_dev || true
echo_and_run umount $root_mnt || true
echo_and_run umount $rootfs_mnt || true
while read dev; do
	if [[ ! -z `cat /proc/mounts | grep "$dev"` ]]; then
		echo "$dev seems to be mounted, unmounting first."
		umount /dev/mapper/$dev
	fi
	echo "deactivating $dev"
	lvchange -a n /dev/mapper/$dev
done < <(lvs --noheadings -o active,vg_name,lv_name | \
	grep $lvm_name | \
 	awk '$1 == "active" {print $2"-"$3}')

cryptsetup close $crypt_dev_name || true

rmdir "$rootfs_mnt" "$root_mnt" 2> /dev/null || true

if [[ -n $image_file ]]; then
        echo "Removing relevant loopback devices:"
        kpartx -dv $image_file
fi
echo "Done."
