# Add info to the configuration file:
#
#     ./get-disk-info.sh /dev/sdc | sed -e 's/^/# /' | tee -a config-zencefil.sh

wwn="..." # if this is set, do not set $image_file
image_file="..." # if this is set, do not set $wwn
lvm_name="foo"

# use ./get-disk-info.sh to identify the UUID's:
boot_part='UUID=4371a575-3a37-476f-8831-05558db4e8a8'
crypt_part='UUID=bf1a7669-e944-444d-83cc-102f34689544'

# you probably won't need to change those:
crypt_dev_name=${lvm_name}_crypt
root_lvm=${lvm_name}-root
swap_lvm=${lvm_name}-swap
subvol=${subvol:-rootfs}

root_dev=/dev/mapper/${root_lvm}
swap_dev=/dev/mapper/${swap_lvm}
root_mnt="/mnt/$root_lvm"
rootfs_mnt="${root_mnt}-${subvol}"
