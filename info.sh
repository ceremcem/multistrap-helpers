#!/bin/bash
set -eu

target=${1:-}
if [[ -z $target ]]; then
	echo "ERROR: rootfs path is required:"
	echo
	echo "    $(basename $0) path/to/rootfs"
	echo
	exit 2
fi

[[ $(whoami) = "root" ]] || { sudo "$0" "$@"; exit 0; }

du -chs $target
