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
if sudo btrfs scrub cancel $root_mnt 2> /dev/null; then
    echo "Cancelling BTRFS scrub."
fi

echo_and_run umount $root_mnt || true
while read dev; do
    device="/dev/mapper/$dev"
	if [[ ! -z `cat /proc/mounts | grep "$dev"` ]]; then
		echo "$dev seems to be mounted, unmounting first."
		if ! umount $device; then
            echo "Close the relevant processes:"
            lsof +f -- $device
            echo "TIP: Try to remount as 'ro' if necessary:"
            echo "mount -o remount,ro $device"
            echo
            echo "(see https://stackoverflow.com/a/58121313/1952991)"
        fi
	fi
	echo "deactivating $device"
	lvchange -a n $device
done < <(lvs --noheadings -o active,vg_name,lv_name | \
	grep $lvm_name | \
 	awk '$1 == "active" {print $2"-"$3}')

cryptsetup close $crypt_dev_name || true

rmdir "$root_mnt" 2> /dev/null || true

if [[ -n ${image_file:-} ]]; then
        echo "Removing relevant loopback devices:"
        kpartx -dv $image_file
fi
echo "Done."
