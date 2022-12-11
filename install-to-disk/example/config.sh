# Follow the multistrap-helpers/install-to-disk/README.md

# Identify your disk (like UUID of a partition). Get this value from
# ./get-disk-info.sh:
wwn="ata-KIOXIA-EXCERIA_SATA_SSD_72RB8191K0Z5"

# Give a name to your LVM volumes. This is usually same as your
# installation name (eg. mysystem)
lvm_name="kanat"

# Define swap_size and make sure that the RAM can fit into the swap area
swap_size="16G"

# Assign below variables *after* partitioning the disk
# (format-btrfs-swap-lvm-luks.sh... step)
# use ./get-disk-info.sh /dev/sdX again to identify the UUID's:
boot_part='UUID=6d2f530b-db0f-4e84-940e-ecbf1749ed05'
crypt_part='UUID=434558cc-ac13-4814-8050-144e70961257'

# OPTIONAL: Define your crypt_key path:
crypt_key="$(cat ./keypath)"

# you probably won't need to change those:
crypt_dev_name=${lvm_name}_crypt
root_lvm=${lvm_name}-root
swap_lvm=${lvm_name}-swap
subvol=${subvol:-rootfs}

root_dev=/dev/mapper/${root_lvm}
swap_dev=/dev/mapper/${swap_lvm}
root_mnt="/mnt/$root_lvm"
