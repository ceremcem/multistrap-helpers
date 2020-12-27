# 1. Create a config file

1. Name your installation (eg. "mysystem")
2. Copy `./config-example.sh` as `config-mysystem.sh` and edit accordingly.
3. First, assign the `wwn=` variable by using `./get-disk-info.sh` (and then `./get-disk-info.sh /dev/sdX`). 
4. Give a name to your LVM volumes by setting `lvm_name=` variable. This is usually the same as your installation name (eg. mysystem).
5. Do not set any other variables at this point. Further instructions will be clarified within the next steps.

> Optional: To prevent any possible mistakes, use `$c` variable instead of `./config-mysystem.sh`:
>
>        export c="./config-mysystem.sh"


# 2. Install to the Physical Disk

1. Create the designed partition layout:

        ./format-btrfs-swap-lvm-luks.sh $c

  This will create the following layout:

		boot partition: _DISK_1
		luks partition: _DISK_2
			lvm:
				/dev/mapper/${lvm_name}-root
				/dev/mapper/${lvm_name}-swap
			
			
2. Use `./get-disk-info.sh /dev/sdX` to assign `boot_part` and `crypt_part` variables in `./config-mysystem.sh`.
		
3. Send `../rootfs.buster` to the target disk and make it bootable:
		
		./attach-disk.sh $c
		./rsync-to-disk.sh $c ../rootfs.buster/			      		  # notice the / character at the end
		./generate-scripts.sh $c -o --rootfs-mnt                      # generate the required scripts for booting
		echo "new-hostname" | sudo tee /path/to/rootfs/etc/hostname   # only if necessary 
		./chroot-to-disk.sh $c                                        # NOTE: displays host's hostname, that's OK
		
		# Run within the chroot environment: 
		# -------------------------------------------------------
		
		# Note: Consider enabling backports: https://backports.debian.org/Instructions/
		
		# ATTENTION: Continue WITHOUT selecting a disk in Grub2 install:
		# 1. Don't select any disk or partition and press "Enter" on "Grub Install" screen.
		# 2. Say "Yes" to "Continue without installing GRUB?" question.
		/1-make-bootable-rootfs.sh
		
		/2-install-grub.sh	

		/3-finalize-and-update.sh 
		# If you encounter complaints about missing firmware, refer to (NOT VERIFIED): https://askubuntu.com/a/1240434/371730

		exit  # from chroot environment		

		# -------------------------------------------------------

		# From within the host
		./detach-disk.sh $c


# Test by using VirtualBox 

1. `./create-vmdk.sh -c $c` # Messages will assist you in the process
2. Open VirtualBox, make appropriate changes (like writethrough, as stated in 1th step)
3. Start the VM.
