1. format-the-server-disk*.sh ...
	boot partition: /dev/sdX1
	luks partition: /dev/sdX2
	lvm on /dev/sdX2:
		/dev/mapper/foo-root
		
2. Install Grub2

	cryptsetup open /dev/sdX2 sdX_crypt
	lvscan
	mount /dev/mapper/foo-root /mnt/foo-root
	btrfs sub create /mnt/foo-root/rootfs
	# if rootfs is a btrfs subvolume, directly mount it 
	# before chroot'ing into it
	mkdir /mnt/foo-actual-root
	mount -t btrfs -o subvol=/rootfs /dev/mapper/foo-root /mnt/foo-actual-root
	mkdir /mnt/foo-actual-root/boot
	mount /dev/sdX1 /mnt/foo-root/rootfs/boot
	rsync -avP multistrap-stretch-rootfs/ /mnt/foo-actual-root
	echo "new-hostname" > /mnt/foo-root/rootfs/etc/hostname

	./do-chroot.sh /mnt/foo-actual-root /make-bootable-rootfs.sh
	grub-install /dev/sdX --boot-directory=/boot

	# create /sbin/init
	apt-get install systemd
	ln -s /lib/systemd/systemd /sbin/init

	# Prevent "root account is locked" error:
	echo "Create a password for your root account:"
	passwd	

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

