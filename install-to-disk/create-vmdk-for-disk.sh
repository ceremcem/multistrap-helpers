#!/bin/bash
set -eu

safe_source () { [[ ! -z ${1:-} ]] && source $1; _dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; _sdir=$(dirname "$(readlink -f "$0")"); }; safe_source

if [[ -b ${1:-} ]]; then
	device=$1
	disk_id=$(ls -l /dev/disk/by-id/ | grep "/$(basename $disk_device)$" | awk '{print $9}' | grep -v wwn)
	disk_path="/dev/disk/by-id/$disk_id"
	vmdk_name="$disk_id.vmdk"
elif [[ -f ${1:-} ]]; then
	file=$1
	lo_device=${2:-}
	[[ -z $lo_device ]] && { echo "Loopback device name is required"; exit 3; }
	vmdk_name="$(basename $file)-$(basename $lo_device).vmdk"
	echo
	echo "Don't forget to associate with the loopback device:"
	echo
	echo "       losetup $lo_device $file"
	echo
else
	echo
	echo "Usage: $(basename $0) /dev/sdX"
	echo "Usage: $(basename $0) /path/to/disk.img"
	echo
	exit 1
fi

[[ $(whoami) = "root" ]] || { sudo "$0" "$@"; exit 0; }
echo "Device: ${device:-$file}, Disk id: ${disk_id:-$lo_device}"

# Taken from: https://superuser.com/a/756731/187576
_device=${disk_path:-$lo_device}
echo "Creating vmdk for ${_device}"
VBoxManage internalcommands createrawvmdk \
    -filename $_sdir/$vmdk_name \
    -rawdisk ${_device}

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
