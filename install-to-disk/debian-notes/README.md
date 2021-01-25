# Don't Break Your Debian

Ensure that your /etc/apt/sources.list[.d/*] files have the same `release` alias (like buster* or stable* or testing*). 

 
# Install missing firmware

* https://unix.stackexchange.com/a/445689/65781

      sudo apt-get install firmware-linux-nonfree 

* Install any further firmware from kernel.org/.../linux-firmware.git:

  http://forums.debian.net/viewtopic.php?f=30&t=145496#p718725

# Install newer kernel 

> See https://unix.stackexchange.com/a/545609/65781

* Enable backports
* apt-get update 
* `sudo apt-get install -t buster-backports linux-image-amd64 btrfs-progs`

