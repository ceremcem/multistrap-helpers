#!/bin/bash

# Simply use lxc-crate to create the contanier?
name=$1
[[ -z $name ]] && { echo "Name is required."; exit 1; }
lxc-create -n $name -t debian -B dir -- -r buster
