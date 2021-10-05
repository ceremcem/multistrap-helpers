#!/bin/bash
set -u

disk_device=${1:-}

file=
if [[ -f $disk_device ]]; then
    file=$disk_device
    sudo kpartx -av $file
    disk_device=$(losetup --associated $file | cut -d: -f1)
    echo "Using loop device: $disk_device for file: $file"
fi

if [[ ! -b $disk_device ]]; then
	cat << EOL

    Possible disks:

$(sudo lsblk -f)

$(losetup -a)


Usage:

    $(basename $0) /dev/sda # use one of the above disks
    -or-
    $(basename $0) path/to/disk.img


EOL
	exit 1
fi

get_wwn_by_device(){
  # usage: get_disk_wwn /dev/sdX
  ls -l /dev/disk/by-id/ | grep "/$(basename $1)$" | awk '{print $9}' | grep -v wwn
}

disk_id=$(get_wwn_by_device $disk_device)

if [[ -n $disk_id ]]; then
    echo "Disk WWN:"
    echo
    echo "	$disk_id"
    echo
fi

sudo lsblk -f $disk_device

[[ -n $file ]] && sudo kpartx -d $file
