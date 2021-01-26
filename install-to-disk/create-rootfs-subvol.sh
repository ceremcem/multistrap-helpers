#!/bin/bash
set -u

config_file=${1:-}
[[ ! -f $config_file ]] && { echo "Missing config file"; exit 1; }
cd "$(dirname "$config_file")"
. $config_file

dest=$root_mnt/$subvol
[[ -d $dest ]] \
    && { echo "$dest already exists."; exit 1; } \
    || { sudo btrfs sub create "$dest"; }
