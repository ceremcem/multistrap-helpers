#!/bin/bash

help(){
	cat << HELP

 chroot into a rootfs for the same architecture
 usage: sudo $(basename $0) rootdir

HELP
}

[[ -d ${1:-} ]] || { help && exit; }

[[ $(whoami) = "root" ]] || { sudo "$0" "$@"; exit 0; }

cmd=
if [[ ! -z ${2:-} ]]; then
	tmp_file=/tmp/cmd.sh
	cmd="--rcfile $tmp_file"
	echo $2 > $1/$tmp_file
	echo "rm $tmp_file" >> $1/$tmp_file
	chmod +x $1/$tmp_file
fi

echo chrooting into $1
mkdir -p $1/proc
mkdir -p $1/sys
mkdir -p $1/dev
mkdir -p $1/run

cat << RESOLV > $1/etc/resolv.conf
nameserver 8.8.8.8
nameserver 8.8.4.4
RESOLV

mount --bind /proc $1/proc
mount --bind /sys $1/sys
mount --bind /dev $1/dev
mount --bind /dev/pts $1/dev/pts
mount --bind /run $1/run

chroot $1 /bin/bash $cmd

echo "Cleaning up..."
umount $1/dev/pts
umount $1/dev
umount $1/sys
umount $1/proc || umount -lf $1/proc
umount $1/run

rm $1/var/lib/dbus/machine-id 2> /dev/null

echo "Cleaned up chroot."
