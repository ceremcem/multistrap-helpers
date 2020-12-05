#!/bin/bash
set -eu

config=${1:-}
if [[ -z $config ]]; then
	echo "You should set the target suite:"
	echo
	echo "    $(basename $0) release.config"
	echo
	exit 2
fi

[[ $(whoami) = "root" ]] || { sudo "$0" "$@"; exit 0; }

release=${config%.*} # remove the .config extension
target_dir=./rootfs.$release
echo "Creating rootfs for Debian $release in $target_dir"
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
		echo "ERROR: $release/dev shouldn't be a mountpoint"
		echo "ERROR: exiting."
		echo "ERROR: "
		exit
	else
		[[ -d $target_dir ]] && rm -rf $target_dir
	fi
fi
multistrap -a amd64 -d $target_dir -f $config

echo "debian" > $target_dir/etc/hostname
cp post-config.sh $target_dir/
./do-chroot.sh $target_dir \
	"[[ -f /post-config.sh ]] && /post-config.sh && rm /post-config.sh; exit 0"

echo "Building $target_dir is finished."
