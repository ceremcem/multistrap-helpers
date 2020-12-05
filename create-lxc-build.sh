#!/bin/bash
# Simply use lxc-crate to create the contanier?

use_x=true # Use X Forwarding?

for pkg in apt-cacher-ng; do
    if ! hash $pkg > /dev/null; then
        echo "*** Tip: Install $pkg on the host ***"
    fi
done

show_usage(){
    local message="$@"
    if [[ -n "$@" ]]; then
        echo
        echo "$@"
        echo
    fi
    cat << EOL

    Usage: 

        $(basename $0) name distro/version

        Example: $(basename $0) my1 debian/buster

        See /usr/share/lxc/templates for available distros
EOL
}

name=$1
[[ -z $name ]] && { show_usage "Name can not be empty"; exit 1; }

distro=$(echo $2 | cut -d/ -f1)
version=$(echo $2 | cut -d/ -f2)

[ -z $distro -o -z $version ] && \
    { show_usage "Distro name can not be empty"; exit 1; }

packages=
if [[ "$use_x" = "true" ]]; then
    echo "Adding X forwarding packages"
    packages="$packages xbase-clients"
fi

# necessary utilities
packages="$packages nano sudo tmux"

dev_pkg="git"
packages="$packages ${dev_pkg}"

# backing store:
bdev="btrfs" # or "dir"

sudo lxc-create -n $name -t $distro -B $bdev \
    --lxcpath /var/lib/lxc \
    -- \
    -r $version \
    --packages $packages \
