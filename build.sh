#!/bin/bash
target_dir=./stretch-rootfs
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
multistrap -a amd64 -d $target_dir -f simple-config

echo "debian" > $target_dir/etc/hostname

echo "Do not forget to run /config-rootfs.sh after you are chrooted"
./do-chroot.sh $target_dir
