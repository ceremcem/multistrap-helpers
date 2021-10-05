# use `./get-disk-info.sh /dev/sdX` to get WWN
wwn="usb-SanDisk_Cruzer_Glide_3.0_4C530001030827103162-0:0"
lvm_name="myexample" # DON'T FORGET TO CHANGE THIS

# use `./get-disk-info.sh /dev/sdX` after creating the disk layout
# to identify the UUID's:
boot_part='UUID=97590f23-55dc-481d-94fe-61f0449840de'
crypt_part='UUID=2941ba48-2dac-4c22-8eac-cb9a652c11e7'
crypt_key="$(cat ./keypath)"

# you probably won't need to change those:
swap_size="2G" # Should be enough to hold RAM on hibernation
crypt_dev_name=${lvm_name}_crypt
root_lvm=${lvm_name}-root
swap_lvm=${lvm_name}-swap
subvol=${subvol:-rootfs}

root_dev=/dev/mapper/${root_lvm}
swap_dev=/dev/mapper/${swap_lvm}
root_mnt="/mnt/$root_lvm"

