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

# show help
# -----------------------------------------------
show_help(){
    cat <<HELP

    Usage: 

        $(basename $0) [options] path/to/config-file

    Options:

        --use-existing-partitions  : Use provided UUID's within config file, 
                                     do not re-create partition table

        --format-entire-disk       : Format entire disk and create a new
                                     partition table

HELP
}

die(){
    echo
    echo "$1"
    show_help
    exit 1
}


# Parse command line arguments
# ---------------------------
# Initialize parameters
config_file=
use_disk="undefined"
# ---------------------------
args_backup=("$@")
args=()
_count=1
while :; do
    key="${1:-}"
    case $key in
        -h|-\?|--help|'')
            show_help    # Display a usage synopsis.
            exit
            ;;
        # --------------------------------------------------------
        --use-existing-partitions)
            use_disk="use-existing-partitions"
            ;;
        --format-entire-disk)
            use_disk="format-entire-disk"
            ;;
        # --------------------------------------------------------
        -*) # Handle unrecognized options
            die "Unknown option: $1"
            ;;
        *)  # Generate the new positional arguments: $arg1, $arg2, ... and ${args[@]}
            if [[ ! -z ${1:-} ]]; then
                declare arg$((_count++))="$1"
                args+=("$1")
            fi
            ;;
    esac
    shift
    [[ -z ${1:-} ]] && break
done; set -- "${args_backup[@]}"
# Use $arg1 in place of $1, $arg2 in place of $2 and so on, 
# "$@" is in the original state,
# use ${args[@]} for new positional arguments  

config_file=${arg1:-}
[[ -f $config_file ]] || die "Config file not found."
safe_source $config_file

[[ $use_disk == "undefined" ]] && \
  die "Explicitly declare: --use-existing-layout or --format-entire-disk."

[[ -n ${wwn:-} ]] && [[ -n ${image_file:-} ]] && \
    die "Either \$wwn or \$image_file should be set in $config_file."

[[ -z $lvm_name ]] && \
    die "\$lvm_name variable should be set in $config_file."

DEVICE=
file=
if [[ -n ${wwn:-} ]]; then 
    DEVICE=$(readlink -f /dev/disk/by-id/$wwn)
    [[ -b $DEVICE ]] || die "$DEVICE should be a device file."
elif [[ -f ${image_file:-} ]]; then
    file=$image_file
    echo "INFO: Handling $file as disk image file."
fi
target=${file:-$DEVICE}

get_device_of_uuid(){
  echo "/dev/$(lsblk -no pkname /dev/disk/by-uuid/${1##UUID=})"
}

if [[ -n $file ]]; then
    kpartx -av "$file"
    DEVICE=$(losetup --associated $file | cut -d: -f1)
    partt1="/dev/mapper/${DEVICE#"/dev/"}p1"
    partt2="/dev/mapper/${DEVICE#"/dev/"}p2"
else
    if [[ "$use_disk" == "format-entire-disk" ]]; then
      partt1="${DEVICE}1"
      partt2="${DEVICE}2"
    elif [[ "$use_disk" == "use-existing-partitions" ]]; then
      partt1=$(readlink -f "/dev/disk/by-uuid/${boot_part##UUID=}")
      partt2=$(readlink -f "/dev/disk/by-uuid/${crypt_part##UUID=}")
      [[ -b $partt1 ]] || die "$partt1 is not a block device."
      [[ "/dev/$(lsblk -no pkname $partt1)" == "$DEVICE" ]] || \
        die "$partt1 does not seem to be on $DEVICE"

      [[ -b $partt2 ]] || die "$partt2 is not a block device."
      [[ "/dev/$(lsblk -no pkname $partt2)" == "$DEVICE" ]] || \
        die "$partt1 does not seem to be on $DEVICE"
    fi
fi

[[ "$use_disk" == "format-entire-disk" ]] && \
  if ! prompt_yes_no "Entire disk ($wwn) will be formatted. Proceed?"; then
    echo "Nothing done."
    exit 1
  fi 

# -----------------------------------------------
# All checks are done. 
# -----------------------------------------------
ROOT_NAME=$lvm_name

if [[ "$use_disk" == "format-entire-disk" ]]; then 
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
else 
  echo "Using existing partitions."
fi

D_DEVICE=${ROOT_NAME}_crypt

SWAP_PART="/dev/mapper/${ROOT_NAME}-swap"
ROOT_PART="/dev/mapper/${ROOT_NAME}-root"

# Double check that we created partitions.
[[ -b $partt1 ]] || \
    die "Something went wrong, there should be a $partt1 device."

info(){ 
  : 
  } # empty function

set -o xtrace # print every command before executing 

info "Creating ext2 filesystem for boot partition"
mkfs.ext2 "$partt1"

info "Creating LUKS layer on $partt2..."
cryptsetup -y -v luksFormat "$partt2"
cryptsetup open "$partt2" $D_DEVICE

info "Creating LVM partitions"
pvcreate "/dev/mapper/$D_DEVICE" || echo_err "physical volume exists.."
vgcreate "${ROOT_NAME}" "/dev/mapper/$D_DEVICE" || echo_err "volume group exists.."
lvcreate -n swap -L 1G $ROOT_NAME
lvcreate -n root -l 100%FREE $ROOT_NAME

info "Formatting swap and root (btrfs) partitions"
mkswap $SWAP_PART
mkfs.btrfs $ROOT_PART

info "Formatting is finished."
info "Closing devices."
lvchange -a n $ROOT_PART
lvchange -a n $SWAP_PART
cryptsetup close $D_DEVICE
[[ -f $file ]] && kpartx -dv $file

info "Dump a overall result"
lsblk -f $DEVICE
