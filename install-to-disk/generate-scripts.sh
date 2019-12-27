#!/bin/bash
set -eu

safe_source () { [[ ! -z ${1:-} ]] && source $1; _dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; _sdir=$(dirname "$(readlink -f "$0")"); }; safe_source

safe_source $_sdir/config.sh

[[ $(whoami) = "root" ]] || { sudo "$0" "$@"; exit 0; }

filename="$rootfs_mnt/install-grub.sh"
echo "Generating $filename"
cat << EOF > $filename
boot_part_dev=\$(blkid | grep ${boot_part##UUID=} | cut -d: -f1)
disk_device=\${boot_part_dev::-1}
grub-install \$disk_device --boot-directory=/boot
EOF
chmod +x $filename

filename="$rootfs_mnt/generate-crypttab.sh"
echo "Generating $filename"
cat << EOF > $filename
echo $crypt_dev_name $crypt_part none luks > /etc/crypttab
EOF
chmod +x $filename


filename="$rootfs_mnt/etc/fstab"
echo "Generating $filename"
cat << EOF > $filename
# <file system> <mount point>   <type>  <options>       <dump>  <pass>
# ----------------------------------------------------------------------------------------
$root_dev /               btrfs        subvol=$subvol,rw,noatime       0       1
$root_dev $root_mnt       btrfs        subvolid=5,rw,noatime       0       1
$boot_part	/boot	ext2	defaults,noatime	0	2
tmpfs /tmp tmpfs defaults,noatime,noexec,nosuid,nodev,mode=1777,size=512M 0 0
EOF
mkdir -p $rootfs_mnt/$root_mnt
