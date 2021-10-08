#!/bin/bash

help(){
	cat << HELP

 chroot into a rootfs for the same architecture
 usage: sudo $(basename $0) rootdir [[--unattended] command-to-execute-in-chroot]

HELP
}

[[ -d ${1:-} ]] || { help && exit; }

[[ $(whoami) = "root" ]] || { sudo "$0" "$@"; exit 0; }

cmd=

rootdir="${1}"
shift

if [[ -n ${1:-} ]]; then
    [[ "$1" == "--unattended" ]] && { sw="-f"; shift; } || sw="--rcfile"
	tmp_file=/tmp/cmd.sh
	cmd="${sw} $tmp_file"
	echo $1 > $rootdir/$tmp_file
	echo "rm $tmp_file" >> $rootdir/$tmp_file
	chmod +x $rootdir/$tmp_file
fi

echo chrooting into $rootdir
mkdir -p $rootdir/proc
mkdir -p $rootdir/sys
mkdir -p $rootdir/dev
mkdir -p $rootdir/run

cat << RESOLV > $rootdir/etc/resolv.conf
nameserver 8.8.8.8
nameserver 8.8.4.4
RESOLV

mount --bind /proc $rootdir/proc
mount --bind /sys $rootdir/sys
mount --bind /dev $rootdir/dev
mount --bind /dev/pts $rootdir/dev/pts
mount --bind /run $rootdir/run

chroot $rootdir /bin/bash $cmd

umount $rootdir/run
umount $rootdir/dev/pts
umount $rootdir/dev
umount $rootdir/sys
umount $rootdir/proc || umount -lf $rootdir/proc

rm $rootdir/var/lib/dbus/machine-id 2> /dev/null

echo "Cleaned up chroot ($rootdir)."
