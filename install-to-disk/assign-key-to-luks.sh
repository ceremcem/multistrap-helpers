#!/bin/bash
set -eu

safe_source () { [[ ! -z ${1:-} ]] && source $1; _dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; _sdir=$(dirname "$(readlink -f "$0")"); }; safe_source


config_file=${1:-}
[[ ! -f $config_file ]] && { echo "Usage: $(basename $0) path/to/config-file"; exit 1; }
safe_source $config_file

[[ -z ${crypt_key:-} ]] && { echo "You should define \$crypt_key variable in your config file."; exit 2; }

if sudo cryptsetup open $crypt_part --test-passphrase --key-file=$crypt_key; then
    echo "This key ($crypt_key) is already assigned."
    exit 0
fi
sudo cryptsetup luksAddKey $crypt_part $crypt_key

