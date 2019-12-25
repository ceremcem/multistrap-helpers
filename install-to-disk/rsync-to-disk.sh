#!/bin/bash
set -eu

safe_source () { [[ ! -z ${1:-} ]] && source $1; _dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; _sdir=$(dirname "$(readlink -f "$0")"); }; safe_source

safe_source $_sdir/config.sh

if [[ -z ${src:-} ]]; then
	echo "Usage: $(basename $0) path/to/your-rootfs"
	exit 1
fi

rsync -avP $src/ $rootfs_mnt
