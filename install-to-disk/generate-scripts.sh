#!/bin/bash
set -eu

safe_source () { [[ ! -z ${1:-} ]] && source $1; _dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; _sdir=$(dirname "$(readlink -f "$0")"); }; safe_source

safe_source $_sdir/config.sh

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
