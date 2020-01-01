#!/bin/bash
set -eu

safe_source () { [[ ! -z ${1:-} ]] && source $1; _dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; _sdir=$(dirname "$(readlink -f "$0")"); }; safe_source

safe_source $_sdir/config.sh

if [[ -b ${1:-} ]]; then
	disk_device=$1
else
    read -p "Use the disk containing the partition with: $boot_part? [y/n]" -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo
        echo "Usage: $(basename $0) /dev/sdX"
        echo
        exit 1
    fi
	boot_part_dev=$(blkid | grep ${boot_part##UUID=} | cut -d: -f1)
	[[ -b $boot_part_dev ]] || { echo "No such partition: $boot_part"; exit 2; }
	disk_device=${boot_part_dev::-1}
fi
disk_id=$(ls -l /dev/disk/by-id/ | grep "/$(basename $disk_device)$" | awk '{print $9}' | grep -v wwn)

[[ $(whoami) = "root" ]] || { sudo "$0" "$@"; exit 0; }
echo "Disk device: $disk_device, Disk id: $disk_id"

# Taken from: https://superuser.com/a/756731/187576

echo "Creating vmdk for $disk_device"
vmdk_name="$disk_id.vmdk"
VBoxManage internalcommands createrawvmdk \
    -filename $_sdir/$vmdk_name \
    -rawdisk /dev/disk/by-id/$disk_id

chown $SUDO_USER:$SUDO_USER "$_sdir/$vmdk_name"
cat << EOF

IMPORTANT: Set To Write-Through
------------

Do not forget to change the mode to "Writethrough"
in the settings before creating the VM:

	File -> Virtual Media Manager
        -> $vmdk_name -> [modify]
            -> Type: Writethrough

EOF

echo "All done."
