# Creating Config File

copy config.sh-example and edit accordingly. Use `get-disk-tag.sh` to get partition
UUID's of your disk.

# Creating Bootable System

Either use a real disk or a disk image to test your installation on VirtualBox. 

"_DISK_" is either "disk.img" or "/dev/sdX" where sdX is your target drive.

# Create a disk image (if necessary)

1. `./create-disk-image ./config.sh`

# Install to Physical Disk

1. Create the designed partition layout:

        ./format-btrfs-swap-lvm-luks.sh ./config.sh

  This will create the following layout:

		boot partition: _DISK_1
		luks partition: _DISK_2
		lvm on _DISK_2:
			/dev/mapper/${lvm_name}-root
			/dev/mapper/${lvm_name}-swap
		
2. Send files to remote disk, install Grub2, configure LUKS:
		
		./attach-disk.sh ./config.sh
		./rsync-to-disk.sh ./config.sh my-rootfs/
		./generate-scripts.sh ./config.sh           # generate the required scripts for booting
		source ./config.sh; echo "new-hostname" > ${rootfs_mnt}/etc/hostname
		./chroot-to-disk.sh ./config.sh
		
		# From this point on, those commands are intended to run 
		# inside the chroot environment: 
		# -------------------------------------------------------
		/make-bootable-rootfs.sh
		/install-grub.sh
		/generate-crypttab.sh
		
		# Add necessary packages for the disk layout:
		apt-get install btrfs-tools lvm2 cryptsetup
		
		# 1. For LUKS partition: 
		#
		#     1. Create the appropriate contents in /etc/crypttab (Optional)
		#
		#          foo_crypt UUID=bf1a7669-e944-444d-83cc-102f34689544 none luks
		#
		#     2. Set "CRYPTSETUP=y" in /etc/cryptsetup-initramfs/conf-hook
		#
		#     3. cat /etc/initramfs-tools/conf.d/cryptroot 
		#
		#	   target=masa_crypt,source=UUID=d8ede8f6-a295-401a-93d8-8f5e3d3f3f2e,rootdev,lvm=masa-root,key=none
		#	   target=masa_crypt,source=UUID=d8ede8f6-a295-401a-93d8-8f5e3d3f3f2e,resumedev,lvm=masa-swap,key=none
		#
		#
		#     XXXX: There is a workaround for now: fix-cryptsetup.sh
		#
		# 3. `update-initramfs -u`
		# 4. `update-grub`


# Test by using VirtualBox 

1. `./create-vmdk-for _DISK_` # Error messages will assist you in the process
