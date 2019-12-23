# Multistrap Example

This scripts are intended to create a Debian rootfs from scratch for: 

	1. Use as LXC container:
		
		host:# ./build.sh 
		host:# ./do-chroot.sh stretch-rootfs
		debian:# /config-rootfs.sh

	2. Create a fully bootable distro/installation:

		## Follow the step #1, and then:
		debian:# /bootable-rootfs.sh
		
		## TODO: Link to rest of the instructions 
		## on "server-setup.git" 

