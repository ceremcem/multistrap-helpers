#!/bin/bash
set -eu

safe_source () { [[ ! -z ${1:-} ]] && source $1; _dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; _sdir=$(dirname "$(readlink -f "$0")"); }; safe_source

safe_source $_sdir/config.sh

if [[ -z ${1:-} ]]; then
	echo "Usage: $(basename $0) path/to/your-rootfs"
	exit 1
fi
src="$1"

rsync -avP $src/ $rootfs_mnt

cat << INSTALL_GRUB > $rootfs_mnt/install-grub.sh
boot_part_dev=\$(blkid | grep ${boot_part##UUID=} | cut -d: -f1)
disk_device=\${boot_part_dev::-1}
grub-install \$disk_device --boot-directory=/boot
INSTALL_GRUB

chmod +x $rootfs_mnt/install-grub.sh
