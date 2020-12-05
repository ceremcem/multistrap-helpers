#!/bin/bash
set -eu
safe_source () { [[ ! -z ${1:-} ]] && source $1; _dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; _sdir=$(dirname "$(readlink -f "$0")"); }; safe_source

errcho () {
    >&2 echo -e "$*"
}

prompt_yes_no () {
    local message=$1
    local OK_TO_CONTINUE="no"
    errcho "----------------------  YES / NO  ----------------------"
    while :; do
        >&2 echo -en "$message (yes/no) "
        read OK_TO_CONTINUE </dev/tty

        if [[ "${OK_TO_CONTINUE}" == "no" ]]; then
            return 1
        elif [[ "${OK_TO_CONTINUE}" == "yes" ]]; then
            return 0
        fi
        errcho "Please type 'yes' or 'no' (you said: $OK_TO_CONTINUE)"
        sleep 1
    done
}


die(){
    echo "$@"
    exit 12
}

[[ $(whoami) = "root" ]] || { sudo "$0" "$@"; exit 0; }

config_file=${1:-}
[[ ! -f $config_file ]] && { echo "Usage: $(basename $0) path/to/config-file"; exit 1; }
safe_source $config_file

[[ -n ${wwn:-} ]] && [[ -n ${image_file:-} ]] && \
    die "Either \$wwn or \$image_file should be set in $config_file."

DEVICE=
file=
if [[ -n ${wwn:-} ]]; then 
    DEVICE=$(readlink -f /dev/disk/by-id/$wwn)
elif [[ -f ${image_file:-} ]]; then
    file=$image_file
    echo "INFO: Handling $file as disk image file."
fi
target=${file:-$DEVICE}

ROOT_NAME=${lvm_name:-}   # zeytin
[[ -z $ROOT_NAME ]] && \
    die "\$lvm_name variable should be set in $config_file."

if prompt_yes_no "We are about to format $target. (lvm name: $lvm_name) Are you sure?"; then
    echo "OK, formatting $target"
else
    die "Nothing has done. Exiting."
fi

D_DEVICE=${ROOT_NAME}_crypt

SWAP_PART="/dev/mapper/${ROOT_NAME}-swap"
ROOT_PART="/dev/mapper/${ROOT_NAME}-root"

echo "Creating partition table on ${target}..."
# to create the partitions programatically (rather than manually)
# we're going to simulate the manual input to fdisk
# The sed script strips off all the comments so that we can
# document what we're doing in-line with the actual commands
# Note that a blank line (commented as "default" will send a empty
# line terminated with a newline to take the fdisk default.
sed -e 's/\s*\([\+0-9a-zA-Z]*\).*/\1/' << EOF | fdisk $target
  o # clear the in memory partition table
  n # new partition
  p # primary partition
  1 # partition number 1
    # default - start at beginning of disk
  +300M # boot parttion
  t # change the type (1st partition will be selected automatically)
  83 # Changed type of partition to 'Linux'
  n # new partition
  p # primary partition
  2 # partion number 2
    # default, start immediately after preceding partition
    # default, extend partition to end of disk
  a # make a partition bootable
  1 # bootable partition is partition 1 -- /dev/sda1
  p # print the in-memory partition table
  w # write the partition table
  q # and we're done
EOF

if [[ -n $file ]]; then
    kpartx -av "$file"
    DEVICE=$(losetup --associated $file | cut -d: -f1)
    partt1="/dev/mapper/${DEVICE#"/dev/"}p1"
    partt2="/dev/mapper/${DEVICE#"/dev/"}p2"
else
    partt1="${DEVICE}1"
    partt2="${DEVICE}2"
fi

[[ -b $DEVICE ]] || \
    die "$DEVICE should be a device file."

# Double check that we created partitions.
[[ -b $partt1 ]] || \
    die "Something went wrong, there should be a $partt1 device."

echo "Creating ext2 filesystem for boot partition"
mkfs.ext2 "$partt1"

echo "Creating LUKS layer on $partt2..."
cryptsetup -y -v luksFormat "$partt2"

cryptsetup open "$partt2" $D_DEVICE

echo "Creating LVM partitions"
pvcreate "/dev/mapper/$D_DEVICE" || echo_err "physical volume exists.."
vgcreate "${ROOT_NAME}" "/dev/mapper/$D_DEVICE" || echo_err "volume group exists.."
lvcreate -n swap -L 1G $ROOT_NAME
lvcreate -n root -l 100%FREE $ROOT_NAME

echo "Formatting swap and root (btrfs) partitions"
mkswap $SWAP_PART
mkfs.btrfs $ROOT_PART

echo "Formatting is finished."
echo "Closing devices. (\$DEVICE: $DEVICE, \$D_DEVICE: $D_DEVICE)"
lvchange -a n $ROOT_PART
lvchange -a n $SWAP_PART
cryptsetup close $D_DEVICE
[[ -f $file ]] && kpartx -dv $file
