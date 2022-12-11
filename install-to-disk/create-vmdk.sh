#!/bin/bash
set -eu

safe_source () { [[ ! -z ${1:-} ]] && source $1; _dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; _sdir=$(dirname "$(readlink -f "$0")"); }; safe_source

die(){ echo "$@"; exit 1; }

if [[ "${1:-}" == "-c" ]]; then
	shift  
	this=$(realpath $0)
	config_file=${1:-}
	[[ -n $config_file && -f $config_file ]] \
	    && config_file=$(realpath $config_file) \
	    || die "Usage: $(basename $0) -c path/to/config-file"
	cd "$(dirname "$config_file")"
	. $config_file
	
	[[ -n ${wwn:-} ]] && { $this "--disk" $wwn; exit 0; }
	[[ -n ${image_file:-} ]] && { $this "--file" "$image_file"; exit 0; }
	echo "Something went wrong. You should set \$wwn or \$image_file."
	exit 1
else
    if [[ "$1" != "--disk" ]] && [[ "$1" != "--file" ]]; then
        die "Usage: $(basename $0) -c path/to/config-file"
    fi
fi

# hack for the internal arguments ("--file" or "--disk")
[[ -n ${1:-} ]] && shift 

if [[ -b /dev/disk/by-id/${1:-} ]]; then
	disk_path="/dev/disk/by-id/${1}"
	vmdk_name="${1}.vmdk"
elif [[ -f ${1:-} ]]; then
	file=$1
	vmdk_name="$(basename $file).vmdk"
	echo "pwd is: $PWD"
else
	die "No device like ${1:-} can be found. Check your config file."
fi

#[[ $(whoami) = "root" ]] || { sudo "$0" "$@"; exit 0; }
_device=${disk_path:-$file}
echo "Device: ${_device}"

# Taken from: https://superuser.com/a/756731/187576
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
