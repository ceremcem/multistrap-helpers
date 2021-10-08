#!/bin/bash
set -eu
safe_source () { [[ ! -z ${1:-} ]] && source $1; _dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; _sdir=$(dirname "$(readlink -f "$0")"); }; safe_source

die(){
    echo "$@"
    exit 1
}

[[ $(whoami) = "root" ]] || die "This script must be run as root."
config_file=${1:-}
shift
[[ -n $config_file && -f $config_file ]] \
    && config_file=$(realpath $config_file) \
    || die "Usage: $(basename $0) path/to/config-file" 
cd "$(dirname "$config_file")"
. $config_file


# create temporary directory for assembly: see https://unix.stackexchange.com/q/558604/65781
tmp="${root_mnt}-${subvol}.chroot"
[[ -d $tmp ]] && die "$tmp exists, not continuing."
echo "Using $tmp for chroot"
mkdir $tmp 
echo "Mounting $subvol (from $root_dev/) on $tmp"
mount $root_dev $tmp -o rw,subvol=$subvol,noatime
echo "Mounting $boot_part to $tmp/boot"
mount $boot_part $tmp/boot
$_sdir/../do-chroot.sh $tmp "$@"
set -x
umount $tmp/boot
umount $tmp
rmdir $tmp
