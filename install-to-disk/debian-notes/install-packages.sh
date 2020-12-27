#!/bin/bash
set -eu
src=${1:-}
[[ -f $src ]] || { echo "Usage: $(basename $0) path/to/installed-packages.txt"; exit 1; }

sudo apt-get install $(grep -v "^#" $src \
    | sed -e 's/#.*//g' \
    | tr '\n' ' ')
