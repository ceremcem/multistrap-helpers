#!/bin/bash
set -eu

target=${1:-}
if [[ -z $target ]]; then
	echo "You should set the target suite:"
	echo
	echo "    $(basename $0) CODENAME"
	echo
	echo "Where the CODENAME might be one of the followings:"
	echo
	for codename in *-config; do
		echo "    * ${codename%%-config}"
	done
	echo
	exit 2
fi

[[ $(whoami) = "root" ]] || { sudo "$0" "$@"; exit 0; }

target_dir=./$target-rootfs
mkdir -p $target_dir
if [ ! -z "$(ls -A $target_dir)" ]; then
	echo "Remove the $target_dir or multistrap will fail."
	echo
	read -p "Remove $target_dir? [y/n]" -n 1 -r
	echo    # (optional) move to a new line
	if [[ ! $REPLY =~ ^[Yy]$ ]]
	then
	    echo "Cancelled removal. Exiting."
	    [[ "$0" = "$BASH_SOURCE" ]] && exit 1 || return 1 # handle exits from shell or function but don't exit interactive shell
	fi
	if mountpoint $target_dir/dev > /dev/null; then
		echo "ERROR: "
		echo "ERROR: Seems to be chrooted to the target."
		echo "ERROR: $target/dev shouldn't be a mountpoint"
		echo "ERROR: exiting."
		echo "ERROR: "
		exit
	else
		[[ -d $target_dir ]] && rm -rf $target_dir
	fi
fi
multistrap -a amd64 -d $target_dir -f $target-config

echo "debian" > $target_dir/etc/hostname
cp post-config.sh $target_dir/
cp install-to-disk/scripts.d/* $target_dir/
./do-chroot.sh $target_dir \
	"[[ -f /post-config.sh ]] && /post-config.sh && rm /post-config.sh"
