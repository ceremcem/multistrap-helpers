#!/bin/bash
set -eu

# CAUTION: Give the arguments in the correct order

DEVICE=$1      # /dev/sdc
ROOT_NAME=$2   # zeytin

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

[[ -b $DEVICE ]] || die "$DEVICE should be a device"

if prompt_yes_no "We are about to format $DEVICE. Are you sure?"; then
    echo "OK, formatting $DEVICE"
else
    echo "Nothing has done. Exiting."
    exit 1
fi


D_DEVICE=${ROOT_NAME}_crypt

NOCOW_PART="/dev/mapper/${ROOT_NAME}-nocow"
ROOT_PART="/dev/mapper/${ROOT_NAME}-root"

echo "Creating partition table on ${DEVICE}..."
umount ${DEVICE}1 2> /dev/null || true
umount ${DEVICE}2 2> /dev/null || true
# to create the partitions programatically (rather than manually)
# we're going to simulate the manual input to fdisk
# The sed script strips off all the comments so that we can
# document what we're doing in-line with the actual commands
# Note that a blank line (commented as "default" will send a empty
# line terminated with a newline to take the fdisk default.
sed -e 's/\s*\([\+0-9a-zA-Z]*\).*/\1/' << EOF | fdisk ${DEVICE}
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

echo "Creating ext2 filesystem for boot partition"
mkfs.ext2 "${DEVICE}1"

echo "Creating LUKS layer on ${DEVICE}2..."
cryptsetup -y -v luksFormat "${DEVICE}2"

cryptsetup open "${DEVICE}2" $D_DEVICE

echo "Creating LVM partitions"
pvcreate "/dev/mapper/$D_DEVICE" || echo_err "physical volume exists.."
vgcreate "${ROOT_NAME}" "/dev/mapper/$D_DEVICE" || echo_err "volume group exists.."
lvcreate -n nocow -L 16G $ROOT_NAME
lvcreate -n root -l 100%FREE $ROOT_NAME

echo "Formatting nocow (ext4) and root (btrfs) partitions"
mkfs.ext4 $NOCOW_PART
mkfs.btrfs $ROOT_PART

echo "done..."
