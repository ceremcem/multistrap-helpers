#!/bin/bash
set -eu

safe_source () { [[ ! -z ${1:-} ]] && source $1; _dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; _sdir=$(dirname "$(readlink -f "$0")"); }; safe_source

show_usage(){
    cat << EOL
    
    Usage: 

        $(basename $0) path/to/config.sh path/to/source-dir/

    TARGET_DIR will be obtained from config file, by \$root_mnt/\$subvol variable.

EOL
}

die(){ show_usage; exit 1; }

src="${2:-}"
[[ -n $src ]] || { echo "Missing source directory"; show_usage; exit 1; } && src=$(realpath $src)

config_file=${1:-}
[[ -n $config_file && -f $config_file ]] \
    && config_file=$(realpath $config_file) \
    || die
cd "$(dirname "$config_file")"
. $config_file

dest=$root_mnt/$subvol
[[ -d $dest ]] || { echo "Missing destination directory ($dest), please create it first."; exit 1; }

echo "Target dir is: $dest"
sleep 1
sudo rsync -avP --delete $src/ $dest/

