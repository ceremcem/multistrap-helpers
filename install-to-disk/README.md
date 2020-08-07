# Install to Physical Disk

1. `format-the-server-disk*.sh` ...

		boot partition: /dev/sdX1
		luks partition: /dev/sdX2
		lvm on /dev/sdX2:
			/dev/mapper/foo-root
		
2. Install Grub2
		
		cp -a ./scripts.d/* my-rootfs/
		./attach-disk.sh
		./rsync-to-disk.sh my-rootfs/
		./generate-scripts.sh
		echo "new-hostname" > /mnt/foo-root/rootfs/etc/hostname
		./chroot-to-disk.sh
		
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


