# Creating Config File

copy config.sh-example and edit accordingly. Use `get-disk-tag.sh` to get partition
UUID's of your disk. Then: 

        export c="./config-foo.sh"

# Creating Bootable System

Either use a real disk or a disk image to test your installation on VirtualBox. 

"_DISK_" is either "disk.img" or "/dev/sdX" where sdX is your target drive.

# FIXME: Create a disk image (if necessary)

> NOTE: There is currently a bug with using disk image. 
> We can not install GRUB to the image. Rest of the scripts
> work just well, like creating, partitioning, attaching and detaching. 

1. `./create-disk-image $c`

# Install to Physical Disk

1. Create the designed partition layout:

        ./format-btrfs-swap-lvm-luks.sh $c

  This will create the following layout:

		boot partition: _DISK_1
		luks partition: _DISK_2
		lvm on _DISK_2:
			/dev/mapper/${lvm_name}-root
			/dev/mapper/${lvm_name}-swap
		
2. Send files to remote disk, install Grub2, configure LUKS:
		
		./attach-disk.sh $c
		./rsync-to-disk.sh $c my-rootfs/
		./generate-scripts.sh $c -o --rootfs-mnt                      # generate the required scripts for booting
		echo "new-hostname" | sudo tee /path/to/rootfs/etc/hostname   # only if necessary 
		./chroot-to-disk.sh $c                                        # displays host's hostname, that's OK
		
		# Run within the chroot environment: 
		# -------------------------------------------------------
		/1-make-bootable-rootfs.sh	# continue without selecting a disk in Grub2 install
		/2-install-grub.sh	
		/3-finalize-and-update.sh  	# If you encounter complaints about missing firmware, refer to (NOT VERIFIED): https://askubuntu.com/a/1240434/371730

		exit  # from chroot environment		
		# -------------------------------------------------------

		# From within the host
		./detach.sh $c


# Test by using VirtualBox 

1. `./create-vmdk-for _DISK_` # Messages will assist you in the process
2. Open VirtualBox, make appropriate changes (like writethrough, as stated in 1th step)
3. Start the VM.
