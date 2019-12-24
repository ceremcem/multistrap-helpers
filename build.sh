#!/bin/bash
target=${1:-stretch}
target_dir=./$target-rootfs
echo "Removing target dir or multistrap will likely fail"
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
multistrap -a amd64 -d $target_dir -f $target-config

echo "debian" > $target_dir/etc/hostname
cp post-config.sh $target_dir/
./do-chroot.sh $target_dir \
	"[[ -f /post-config.sh ]] && /post-config.sh && rm /post-config.sh"
