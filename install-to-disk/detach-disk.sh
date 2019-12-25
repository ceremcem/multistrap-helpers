#!/bin/bash
set -eu

safe_source () { [[ ! -z ${1:-} ]] && source $1; _dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; _sdir=$(dirname "$(readlink -f "$0")"); }; safe_source

safe_source $_sdir/config.sh

echo "Detaching ${lvm_name}..."
boot_part_dev=$(blkid | grep ${boot_part##UUID=} | cut -d: -f1)
umount $boot_part_dev || true
umount $root_mnt || true
umount $rootfs_mnt || true
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
echo "Done."
