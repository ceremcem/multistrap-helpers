#!/bin/bash
set -eu

# CAUTION: Give the arguments in the correct order

target=$1      # /dev/sdc or /path/to/disk.img
ROOT_NAME=$2   # zeytin

file=
if [[ -f $target ]]; then
    echo "Handling $target as disk image file."
    file=$target
fi

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

DEVICE=
cleanup(){
	cat <<EOL

	INFO: Created devices are not umounted.
	INFO: You should manually umount when you are done:

		1. Create the config file.
		2. Run ./detach-disk.sh

EOL
}

trap cleanup EXIT

if prompt_yes_no "We are about to format $target. Are you sure?"; then
    echo "OK, formatting $target"
else
    echo "Nothing has done. Exiting."
    exit 1
fi

[[ $(whoami) = "root" ]] || { sudo "$0" "$@"; exit 0; }

if [[ -n "$file" ]]; then
    DEVICE=`losetup -f`
    echo "Using loop device: $DEVICE"
    losetup "$DEVICE" "$file"
else
    DEVICE=$target
fi

[[ -b $DEVICE ]] || die "$DEVICE should be a device"

D_DEVICE=${ROOT_NAME}_crypt

SWAP_PART="/dev/mapper/${ROOT_NAME}-swap"
ROOT_PART="/dev/mapper/${ROOT_NAME}-root"

echo "Creating partition table on ${DEVICE}..."
# to create the partitions programatically (rather than manually)
# we're going to simulate the manual input to fdisk
# The sed script strips off all the comments so that we can
# document what we're doing in-line with the actual commands
# Note that a blank line (commented as "default" will send a empty
# line terminated with a newline to take the fdisk default.
sed -e 's/\s*\([\+0-9a-zA-Z]*\).*/\1/' << EOF | fdisk ${file:-DEVICE}
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

if [[ -z "$file" ]]; then
    partt1="${DEVICE}1"
    partt2="${DEVICE}2"
else
    kpartx -av "$file"
    partt1="/dev/mapper/${DEVICE#"/dev/"}p1"
    partt2="/dev/mapper/${DEVICE#"/dev/"}p2"

    [[ -d $(readlink $partt1) ]] || { echo "No $partt1 device";  }
fi

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
