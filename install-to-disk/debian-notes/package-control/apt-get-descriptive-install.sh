#!/bin/bash
safe_source () { [[ ! -z ${1:-} ]] && source $1; _dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; _sdir=$(dirname "$(readlink -f "$0")"); }; safe_source
set -eu

[[ -z ${1:-} ]] && { echo "At least one package is required."; exit 1; }

read -p "Description (eg. foo-deps): " _desc
desc=$(echo $_desc | sed -r 's/\s/-/g')
[[ "$desc" != "$_desc" ]] && echo "(Replaced spaces with hyphens: $desc)"

cd "$_sdir"
mkdir -p ./packages
cd ./packages
tmpfile=$(mktemp ./$(basename $0).XXXXXX)
../create-virtual-deps.sh --name $desc $@ | tee $tmpfile

install=$(cat $tmpfile | grep "sudo apt install")
rm "$tmpfile"
$install

echo "INFO: Deb package is kept in $PWD"
