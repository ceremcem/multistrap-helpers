#!/bin/bash
safe_source () { [[ ! -z ${1:-} ]] && source $1; _dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; _sdir=$(dirname "$(readlink -f "$0")"); }; safe_source

die(){ echo "$@"; exit 1; }

config_file=${1:-}
[[ -n $config_file && -f $config_file ]] \
    && config_file=$(realpath $config_file) \
    || die "Usage: $(basename $0) path/to/config-file"
cd "$(dirname "$config_file")"
. $config_file

[[ -z $image_file ]] && { echo "Define image_file='path/to/disk.img' in your config."; exit 1; }
[[ -e $image_file ]] && { echo "ERROR: $image_file already exists."; exit 1; }

# Causes fragmentation:
#dd if=/dev/zero of="$image_file" bs=1024k seek=35600 count=0

# Creates file without causing fragmentation:
fallocate -l 35G "$image_file"

echo "$image_file is created."