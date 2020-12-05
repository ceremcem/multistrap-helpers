#!/bin/bash
get_wwn_by_device(){
  # usage: get_wwn_by_device /dev/sdX
  local device=$1
  ls -l /dev/disk/by-id/ | grep "/$(basename $device)$" | awk '{print $9}' | grep -v wwn
}

get_device_by_wwn(){
  # usage: get_device_by_wwn the-wwn-string-of-disk-device
  local wwn=$1
  readlink -f /dev/disk/by-id/$wwn)
}
