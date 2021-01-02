#!/bin/bash
set -eu

safe_source () { [[ ! -z ${1:-} ]] && source $1; _dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; _sdir=$(dirname "$(readlink -f "$0")"); }; safe_source

function echo_and_run {
  echo "$@"
  eval $(printf '%q ' "$@") < /dev/tty
}

lvm_open_count(){
    local device=$1
    dmsetup info $device | grep "Open count" | cut -d: -f2 | tr -d ' '
}

config_file=${1:-}
[[ ! -f $config_file ]] && { echo "Usage: $(basename $0) path/to/config-file"; exit 1; }
safe_source $config_file

[[ $(whoami) = "root" ]] || { sudo "$0" "$@"; exit 0; }

echo "Detaching ${lvm_name}..."
if sudo btrfs scrub cancel $root_mnt 2> /dev/null; then
    echo "Cancelling BTRFS scrub."
fi

if mountpoint $root_mnt > /dev/null; then
    echo "Unmounting $root_mnt"
    umount $root_mnt
else
    echo "INFO: $root_mnt is not mounted."
fi 

while read _dev; do
    [[ -z $_dev ]] && continue
    dev="${lvm_name}-${_dev}"
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
	echo "Deactivating LVM volume: $device"
	lvchange -a n $device || dmsetup remove $device
done <<< $(ls /dev/$lvm_name 2> /dev/null) 


echo -n "Closing $crypt_dev_name: "
cryptsetup close $crypt_dev_name && echo "OK" || exit 1; 

echo "Removing $root_mnt directory"
rmdir "$root_mnt" 2> /dev/null || true

if [[ -n ${image_file:-} ]]; then
        echo "Removing relevant loopback devices:"
        kpartx -dv $image_file
fi
echo "$lvm_name is detached."
