#!/bin/bash
set -u

die(){ echo "$@"; exit 1; }

config_file=${1:-}
[[ -n $config_file && -f $config_file ]] \
    && config_file=$(realpath $config_file) \
    || die "Configuration file is required." 
cd "$(dirname "$config_file")"
. $config_file

dest=$root_mnt/$subvol
[[ -d $dest ]] \
    && { echo "$dest already exists."; exit 1; } \
    || { sudo btrfs sub create "$dest"; }
