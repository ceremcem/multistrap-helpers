#!/bin/bash
set -eu

safe_source () { [[ ! -z ${1:-} ]] && source $1; _dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; _sdir=$(dirname "$(readlink -f "$0")"); }; safe_source

safe_source $_sdir/config.sh

boot_part_dev=$(blkid | grep ${boot_part##UUID=} | cut -d: -f1)
disk_device=${boot_part_dev::-1}

[[ $(whoami) = "root" ]] || { sudo "$0" "$@"; exit 0; }

# Taken from: https://superuser.com/a/756731/187576

echo "Creating vmdk for $disk_device"
vmdk_name="$(basename $disk_device).vmdk"
VBoxManage internalcommands createrawvmdk \
    -filename $_sdir/$vmdk_name \
    -rawdisk $disk_device

chown $SUDO_USER:$SUDO_USER "$_sdir/$vmdk_name"
cat << EOF
Do not for get to change the mode to "Writethrough"
in the settings before creating the VM:

	File -> Virtual Media Manager
		-> $vmdk_name -> [modify] -> Type: Writethrough

EOF

while true; do
    read -p "Did you set the mode to Writethrough?" yn
    case $yn in
        [Yy][Ee][Ss] )break;;
        * ) echo "You can only answer as YES to continue";;
    esac
done

echo "All done."
