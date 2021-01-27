#!/bin/bash
set -eu

safe_source () { [[ ! -z ${1:-} ]] && source $1; _dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; _sdir=$(dirname "$(readlink -f "$0")"); }; safe_source

die(){ echo "$@"; exit 1; }

if [[ "${1:-}" == "-c" ]]; then
	shift  
	config_file=${1:-}
	[[ -n $config_file && -f $config_file ]] \
	    && config_file=$(realpath $config_file) \
	    || die "Usage: $(basename $0) -c path/to/config-file"
	. $config_file

	this=$(realpath $0)
	cd "$(dirname $config_file)" # create vmdk file in the same directory of config file.
	[[ -n ${wwn:-} ]] && { $this "--disk" $wwn; exit 0; }
	[[ -n ${image_file:-} ]] && { $this "--file" "$image_file"; exit 0; }
	echo "Something went wrong. You should set \$wwn or \$image_file."
	exit 1
fi

# hack for first arguments
[[ -n ${1:-} ]] && shift 

if [[ -b ${1:-} ]]; then
	device=$(readlink -f $1)
	disk_id=$(ls -l /dev/disk/by-id/ | grep "/$(basename $device)$" | awk '{print $9}' | grep -v wwn)
	disk_path="/dev/disk/by-id/$disk_id"
	vmdk_name="$disk_id.vmdk"
elif [[ -f ${1:-} ]]; then
	file=$1
	vmdk_name="$(basename $file).vmdk"
	echo "pwd is: $PWD"
else
	die "Usage: $(basename $0) -c path/to/config-file"
fi

#[[ $(whoami) = "root" ]] || { sudo "$0" "$@"; exit 0; }
echo "Device: ${disk_path:-$file}, Disk id: ${disk_id:-$file}"

# Taken from: https://superuser.com/a/756731/187576
_device=${disk_path:-$file}
vmdk_name="virtualbox-$vmdk_name"
echo "Creating vmdk for ${_device}"
VBoxManage internalcommands createrawvmdk \
    -filename ./$vmdk_name \
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
