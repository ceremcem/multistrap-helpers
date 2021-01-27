#!/bin/bash
set -u

die(){ echo "$@"; exit 1; }

config_file=${1:-}
[[ -n $config_file && -f $config_file ]] \
    && config_file=$(realpath $config_file) \
    || die "Configuration file is required." 
. $config_file

dest=$root_mnt/$subvol

hostname=${2:-$lvm_name}
set -x 
echo $hostname | sudo tee "$dest/etc/hostname"