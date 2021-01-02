#!/bin/bash
set -eu
safe_source () { [[ ! -z ${1:-} ]] && source $1; _dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; _sdir=$(dirname "$(readlink -f "$0")"); }; safe_source

die(){
    echo "$@"
    exit 1
}

config_file=${1:-}
[[ ! -f $config_file ]] && { echo "Usage: $(basename $0) path/to/config-file"; exit 1; }
safe_source $config_file

[[ $(whoami) = "root" ]] || die "This script must be run as root."

shift
args=("${@:-}")

# create temporary directory for assembly: see https://unix.stackexchange.com/q/558604/65781
tmp="${root_mnt}-${subvol}.chroot"
[[ -d $tmp ]] && die "$tmp exists, not continuing."
echo "Using $tmp for chroot"
mkdir $tmp 
echo "Mounting $subvol from $root_dev on $tmp"
mount $root_dev $tmp -o rw,subvol=$subvol,noatime
echo "Mounting \$boot_part to $tmp/boot"
mount $boot_part $tmp/boot
$_sdir/../do-chroot.sh $tmp "$args"
set +x
umount $tmp/boot
umount $tmp
rmdir $tmp
