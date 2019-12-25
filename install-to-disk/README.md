# Install to Physical Disk

1. `format-the-server-disk*.sh` ...

		boot partition: /dev/sdX1
		luks partition: /dev/sdX2
		lvm on /dev/sdX2:
			/dev/mapper/foo-root
		
2. Install Grub2

		./attach-disk.sh
		./rsync-to-disk.sh my-rootfs/
		echo "new-hostname" > /mnt/foo-root/rootfs/etc/hostname
		./chroot-to-disk.sh
		
		# From this point on, those commands are intended to run 
		# inside the chroot environment: 
		# -------------------------------------------------------
		/make-bootable-rootfs.sh
		grub-install /dev/sdX --boot-directory=/boot

		# Add necessary tools to the initramfs if 
		# needed, such as cryptsetup and lvm:
		# 
		# 1. For LUKS partition: 
		#
		#     1. Create the appropriate contents in /etc/crypttab (Optional)
		#
		#          foo_crypt UUID=bf1a7669-e944-444d-83cc-102f34689544 none luks
		# 
		#     2. `apt-get install cryptsetup`
		#
		#     3. Set "CRYPTSETUP=y" in /etc/cryptsetup-initramfs/conf-hook
		#
		#     4. cat /etc/initramfs-tools/conf.d/cryptroot 
		#
		#	   target=masa_crypt,source=UUID=d8ede8f6-a295-401a-93d8-8f5e3d3f3f2e,rootdev,lvm=masa-root,key=none
		#	   target=masa_crypt,source=UUID=d8ede8f6-a295-401a-93d8-8f5e3d3f3f2e,resumedev,lvm=masa-swap,key=none
		#
		#
		#     XXXX: There is a workaround for now: fix-cryptsetup.sh
		#
		# 2. For LVM partition:
		#
		#     1. `apt-get install lvm2`
		# 
		# 3. `update-initramfs -u`
		# 4. `update-grub`


