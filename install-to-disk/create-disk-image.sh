#!/bin/bash

image_file="$1"
[[ -z $image_file ]] && { echo "USAGE: $(basename $0) path/to/disk.img"; exit 1; }
[[ -e $image_file ]] && { echo "ERROR: $image_file already exists."; exit 1; }
# create 15G disk image
dd if=/dev/zero of="$image_file" bs=1024k seek=15600 count=0
