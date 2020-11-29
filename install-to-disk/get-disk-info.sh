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

Usage:

    $(basename $0) /dev/sda
    -or-
    $(basename $0) path/to/disk.img

    Possible disks:

$(ls -l /dev/disk/by-id/ \
    | grep "/sd.$" \
    | grep -v 'wwn' \
    | awk '{printf $9" "$10" "; system("readlink -f /dev/disk/by-id/"$11);}')
$(losetup -a)

EOL
	exit 1
fi

disk_id=$(ls -l /dev/disk/by-id/ | grep "/$(basename $disk_device)$" | awk '{print $9}' | grep -v wwn)

if [[ -n $disk_id ]]; then
    echo "Disk WWN:"
    echo
    echo "	$disk_id"
    echo
fi

echo "UUID information: "
echo
sudo blkid | grep $(basename $disk_device)

[[ -n $file ]] && sudo kpartx -d $file
