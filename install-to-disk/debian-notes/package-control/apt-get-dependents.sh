#!/bin/bash
#
# https://askubuntu.com/a/128527/371730
#
set -eu
apt-cache rdepends $@ \
    | sed -n -e '/Reverse Depends:/,$p' \
    | sed 1,1d \
    | uniq
