#!/bin/bash
set -e
if [ "$(stat -c %d:%i /)" != "$(stat -c %d:%i /proc/1/root/.)" ]; then
  echo "Preparing bootable rootfs"
else
  echo "This script is intended to be run in chroot environment!"
  exit 1
fi

apt-get update
apt-get install -y linux-image-amd64 \
	grub2 \
	systemd \
	initramfs-tools \
	kbd \
    crudini
[[ -e /sbin/init ]] || ln -s /lib/systemd/systemd /sbin/init

update_cfg(){
    local file=$1
    local key=$2
    local value=$3
    crudini --set --inplace $file '' $key $value
    # workaround, see https://github.com/ceremcem/multistrap-helpers/issues/15
    sed -i -r "s/(\S*)\s*=\s*(.*)/\1=\2/g" $file 
}

# edit initramfs.conf to change KEYMAP=y
update_cfg /etc/initramfs-tools/initramfs.conf KEYMAP y

# For cryptsetup installations
apt-get install -y btrfs-progs lvm2 cryptsetup
update_cfg /etc/cryptsetup-initramfs/conf-hook CRYPTSETUP y

# Prevent "root account is locked" error:
echo "Create a password for your root account:"
passwd
