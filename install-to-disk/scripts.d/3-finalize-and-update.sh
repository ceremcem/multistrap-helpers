#!/bin/bash

# Add necessary packages for the disk layout:
apt-get install btrfs-progs lvm2 cryptsetup

crudini --set --inplace /etc/cryptsetup-initramfs/conf-hook '' CRYPTSETUP y

update-initramfs -u -k all
update-grub
