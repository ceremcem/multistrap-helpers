# Multistrap Helpers

These scripts are intended to create a Debian rootfs from scratch. You can later use it 
for creating an LXC container and later (or immediately, without creating an LXC container) 
create a real installation. 

1. Create the rootfs:
		
	```console
	root@host:# ./create-rootfs.sh buster.config
	```

    You can use the `rootfs.buster` as an LXC container rootfs or real installation. 

    > Note: You can **not** use a rootfs for real installation that is 
    > created with `create-lxc-build.sh`. (see [this issue](https://unix.stackexchange.com/q/622913/65781)). 

2. Create a fully bootable distro/installation:

	1. Follow the step #1
	2. Follow the instructions: [./install-to-disk](./install-to-disk).

# Dependencies 

```
apt-get install multistrap
```
