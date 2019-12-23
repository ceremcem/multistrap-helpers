# Multistrap Example

This scripts are intended to create a Debian rootfs from scratch for: 

1. Use as LXC container:
		
	```console
	root@host:# ./build.sh 
	# only once after the build phase:
	root@debian:# /config-rootfs.sh 
	```

2. Create a fully bootable distro/installation:

	```console
	## Follow the step #1, and then:
	root@debian:# /bootable-rootfs.sh

	## TODO: Link to rest of the instructions 
	## on "server-setup.git" 
	```

