#!/bin/bash
set -eu

if [[ ! -b ${1:-} ]]; then
	cat << EOL

Usage:

	$(basename $0) /dev/sda

    Possible disks:

$(ls -l /dev/disk/by-id/ \
    | grep "/sd.$" \
    | grep -v 'wwn' \
    | awk '{printf $9" "$10" "; system("readlink -f /dev/disk/by-id/"$11);}')

EOL
	exit 1
fi

disk_device=$1
disk_id=$(ls -l /dev/disk/by-id/ | grep "/$(basename $disk_device)$" | awk '{print $9}' | grep -v wwn)

echo "Disk WWN:"
echo
echo "	$disk_id"
echo
echo "Other useful information: "
echo
blkid | grep $disk_device
