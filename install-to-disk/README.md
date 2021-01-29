# 1. Create a config file

1. Create a configuration file by modifying `config-example.sh`. 
2. Fill variables in "Phase 1/2".

> Recommended: To prevent any possible mistakes, use a (eg. `$c`) variable:
>
>      c="path/to/mysystem/config.sh"

# 2. Install to the Physical Disk

> You may create an image file by using `./create-disk-image.sh $c`.

1. Create the designed partition layout:

		# Either --use-existing-layout or --format-entire-disk
        ./format-btrfs-swap-lvm-luks.sh $c --use-one-of-the-above-switches

        # Optional: Assign a key to your LUKS partition for auto mounting
        ./assign-key-to-luks.sh $c

  This will create the following layout:

		boot partition
		luks partition:
			lvm:
				/dev/mapper/${lvm_name}-root
				/dev/mapper/${lvm_name}-swap
			
			
2. Use the given information in the previous step (or manually get by `./get-disk-info.sh /dev/sdX`) to assign `boot_part` and `crypt_part` variables in your config file (Phase 2/2).
		
3. Send `../rootfs.buster` to the target disk and make it bootable:
		
		./attach-disk.sh $c
		./create-rootfs-subvol.sh $c
		./rsync-to-disk.sh $c ../rootfs.buster/		 # notice the / character at the end
		sudo ./generate-scripts.sh $c -o --rootfs    # generate the required scripts for booting
		./set-hostname.sh $c   						 # optional 
		sudo ./chroot-to-disk.sh $c                  # NOTE: Still displays HOST's hostname, that's OK
		
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
2. Open VirtualBox, make appropriate changes (like writethrough, as stated in 1st step)
3. Start the VM.
