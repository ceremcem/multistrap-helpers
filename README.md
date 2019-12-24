# Multistrap Example

This scripts are intended to create a Debian rootfs from scratch for: 

1. Use as LXC container:
		
	```console
	root@host:# ./build.sh 
	# only once after the build phase:
	root@debian:# /config-rootfs.sh 
	```

2. Create a fully bootable distro/installation:

	## Follow the step #1, and then follow
	## README.md in ./install-to-disk/
