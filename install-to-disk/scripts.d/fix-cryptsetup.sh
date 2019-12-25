#!/bin/bash

# from http://web.math.rochester.edu/people/faculty/akrish11//2018/04/28/debian-cryptroot.html
# -------------------
#cp -av /usr/share/initramfs-tools/scripts/local-top/cryptroot /etc/initramfs-tools/scripts/local-top/cryptroot
##mkdir -p /etc/initramfs-tools/scripts/local-block
##cp -av /usr/share/initramfs-tools/scripts/local-block/cryptroot /etc/initramfs-tools/scripts/local-block/cryptroot
##cp -av /usr/share/initramfs-tools/hooks/cryptkeyctl /etc/initramfs-tools/scripts/local-block/cryptroot
cp -av /usr/share/initramfs-tools/hooks/cryptroot /etc/initramfs-tools/hooks/

update-initramfs -u -t
echo "done."
