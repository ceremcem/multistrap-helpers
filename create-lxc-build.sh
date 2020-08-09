#!/bin/bash
# Simply use lxc-crate to create the contanier?

use_x=true

for pkg in apt-cacher-ng; do
    if ! hash $pkg > /dev/null; then
        echo "*** Tip: Install $pkg on the host ***"
    fi
done

name=$1
[[ -z $name ]] && { echo "Name is required."; exit 1; }

packages=
if [[ "$use_x" = "true" ]]; then
    echo "Adding X forwarding packages"
    packages="$packages xbase-clients"
fi

dev_pkg="git"

packages="$packages ${dev_pkg}"

sudo lxc-create -n $name -t debian -B dir -- -r buster \
    --packages "nano ${packages}"
