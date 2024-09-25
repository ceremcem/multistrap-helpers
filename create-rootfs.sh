#!/bin/bash
set -eu -o pipefail
safe_source () { [[ ! -z ${1:-} ]] && source $1; _dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; _sdir=$(dirname "$(readlink -f "$0")"); }; safe_source
# end of bash boilerplate

# magic variables
# $_dir  : this script's (or softlink's) directory
# $_sdir : this script's real file's directory

show_help(){
    cat <<HELP

    $(basename $0) [options] path/to/release.config

    Options:

        --subvolume      : Download into a subvolume 
		--arch 			 : Architecture (default: amd64)

HELP
}

die(){
    >&2 echo
    >&2 echo "$@"
    exit 1
}

help_die(){
    >&2 echo
    >&2 echo "$@"
    show_help
    exit 1
}

# Parse command line arguments
# ---------------------------
# Initialize parameters
subvolume=false
arch="amd64"
# ---------------------------
args_backup=("$@")
args=()
_count=1
while [ $# -gt 0 ]; do
    key="${1:-}"
    case $key in
        -h|-\?|--help|'')
            show_help    # Display a usage synopsis.
            exit
            ;;
        # --------------------------------------------------------
        --subvolume)
            subvolume=true
            ;;
        # --------------------------------------------------------
        -*) # Handle unrecognized options
            help_die "Unknown option: $1"
            ;;
        *)  # Generate the new positional arguments: $arg1, $arg2, ... and ${args[@]}
            if [[ ! -z ${1:-} ]]; then
                declare arg$((_count++))="$1"
                args+=("$1")
            fi
            ;;
    esac
    [[ -z ${1:-} ]] && break || shift
done; set -- "${args_backup[@]-}"
# Use $arg1 in place of $1, $arg2 in place of $2 and so on, 
# "$@" is in the original state,
# use ${args[@]} for new positional arguments  


# Empty argument checking
# -----------------------------------------------
[[ -z ${arg1:-} ]] && help_die "Config is required"
config=$arg1

[[ $(whoami) = "root" ]] || exec sudo "$0" "$@"

release=$(basename $config)
release=${release%.*} # remove the .config extension
target_dir="$_dir/rootfs.$release"
echo "Creating rootfs for Debian $release in $(realpath $target_dir)"

if $subvolume; then 
	[[ -e "$target_dir" ]] || btrfs sub create "$target_dir"
else 
	mkdir -p "$target_dir"
fi 
if [ ! -z "$(ls -A $target_dir)" ]; then
	echo "Remove the contents of $target_dir"
	exit 1
fi 

if [[ -d "$target_dir/dev" ]]; then 
	if mountpoint $target_dir/dev > /dev/null; then
		echo "ERROR: "
		echo "ERROR: Seems to be chrooted to the target."
		echo "ERROR: $release/dev shouldn't be a mountpoint"
		echo "ERROR: exiting."
		echo "ERROR: "
		exit
	fi
fi

# create rootfs 
multistrap -a $arch -d "$target_dir" -f "$config"

echo "debian" > "$target_dir/etc/hostname"
cp "$_sdir/post-config.sh" "$target_dir/"
"$_sdir/do-chroot.sh" "$target_dir" \
	"[[ -f /post-config.sh ]] && /post-config.sh && rm /post-config.sh; exit 0"

echo "Building $target_dir is finished."
