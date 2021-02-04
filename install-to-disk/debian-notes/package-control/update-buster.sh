#!/bin/bash
set -e
[[ "$(whoami)" == "root" ]] || { sudo $0 "$@"; exit 0; }

set -x
apt-get update

sudo service vboxdrv stop
sudo apt-get upgrade

set +x
echo "Upgrading packages manually installed from backports:"
aptitude search "?narrow(~i, ~Abackports) ?not(?automatic)" \
    | awk '{print $2}' \
    | xargs apt-get -t buster-backports install

set -x
sudo apt-get dist-upgrade

/sbin/vboxconfig
sudo service vboxdrv start

