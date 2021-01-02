#!/bin/bash
set -eu

safe_source () { [[ ! -z ${1:-} ]] && source $1; _dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; _sdir=$(dirname "$(readlink -f "$0")"); }; safe_source

if [[ "$1" == "-c" ]]; then 
	source $2
	disk_id=$wwn 
	disk_path="/dev/disk/by-id/$disk_id"
	vmdk_name="$disk_id.vmdk"
elif [[ -b ${1:-} ]]; then
	device=$(readlink -f $1)
	disk_id=$(ls -l /dev/disk/by-id/ | grep "/$(basename $device)$" | awk '{print $9}' | grep -v wwn)
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
	echo "Usage: $(basename $0) -c path/to/config.sh"
	echo "Usage: $(basename $0) /dev/sdX"
	echo "Usage: $(basename $0) /dev/disk/by-id/disk-wwn"
	echo "Usage: $(basename $0) /path/to/disk.img"
	echo
	exit 1
fi

#[[ $(whoami) = "root" ]] || { sudo "$0" "$@"; exit 0; }
echo "Device: ${disk_path:-$file}, Disk id: ${disk_id:-$lo_device}"

# Taken from: https://superuser.com/a/756731/187576
_device=${disk_path:-$lo_device}
vmdk_name="virtualbox-$vmdk_name"
echo "Creating vmdk for ${_device}"
VBoxManage internalcommands createrawvmdk \
    -filename $_sdir/$vmdk_name \
    -rawdisk ${_device}

#chown $SUDO_USER:$SUDO_USER "$_sdir/$vmdk_name"
cat << EOF

1. Change .vmdk type to "Write-Through":

	File -> Virtual Media Manager
		-> add
        -> $vmdk_name -> [Attributes]
            -> Type: Writethrough

2. Ensure that you have r/w permissions to the $_device file: 

	$(ls -l $_device)

3. Create your virtual machine by using $vmdk_name. 
EOF

echo "All done."
