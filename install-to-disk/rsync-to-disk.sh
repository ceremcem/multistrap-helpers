#!/bin/bash
set -eu

safe_source () { [[ ! -z ${1:-} ]] && source $1; _dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; _sdir=$(dirname "$(readlink -f "$0")"); }; safe_source

show_usage(){
    cat << EOL
    
    Usage: 

        $(basename $0) path/to/config.sh path/to/source-dir

    TARGET_DIR will be obtained from config file, by \$root_mnt/\$subvol variable.

EOL
}

config_file=${1:-}
[[ ! -f $config_file ]] && { echo "Missing config file"; show_usage; exit 1; }
safe_source $config_file

src="${2:-}"
[[ -n $src ]] || { echo "Missing source directory"; show_usage; exit 1; }

dest=$root_mnt/$subvol
[[ -d $dest ]] || { echo "Missing destination directory, please create it first."; exit 1; }

[[ $(whoami) = "root" ]] || { sudo "$0" "$@"; exit 0; }

echo "Target dir is: $dest"
sleep 1
rsync -avP --delete $src/ $dest/

