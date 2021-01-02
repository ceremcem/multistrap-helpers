#!/bin/bash
set -e
# Add necessary packages for the disk layout:
apt-get install btrfs-progs lvm2 cryptsetup

crudini --set --inplace /etc/cryptsetup-initramfs/conf-hook '' CRYPTSETUP y
sed -i -r "s/(\S*)\s*=\s*(.*)/\1=\2/g" /etc/cryptsetup-initramfs/conf-hook

update-initramfs -u -k all
update-grub
