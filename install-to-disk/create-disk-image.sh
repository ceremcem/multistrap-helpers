#!/bin/bash
safe_source () { [[ ! -z ${1:-} ]] && source $1; _dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; _sdir=$(dirname "$(readlink -f "$0")"); }; safe_source

config_file=${1:-}
[[ ! -f $config_file ]] && { echo "Usage: $(basename $0) path/to/config-file"; exit 1; }
cd "$(dirname "$config_file")"
safe_source $config_file

[[ -z $image_file ]] && { echo "Define image_file='path/to/disk.img' in your config."; exit 1; }
[[ -e $image_file ]] && { echo "ERROR: $image_file already exists."; exit 1; }

size=35600
dd if=/dev/zero of="$image_file" bs=1024k seek=$size count=0
