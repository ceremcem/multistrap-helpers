#!/bin/bash
set -eu
safe_source () { [[ ! -z ${1:-} ]] && source $1; _dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; _sdir=$(dirname "$(readlink -f "$0")"); }; safe_source

get_file_permissions(){
    # Gets file permissions in octal format (without leading zero)
    # Usage example: chmod $(get_file_permissions path/to/src) path/to/target
    stat -c '%a' $1
}

timestamp(){
    date '+%Y%m%dT%H%M'
}

# show help
# -----------------------------------------------
show_help(){
    cat <<HELP
    Generates actual scripts from ./scripts.d by using config-file. 

    $(basename $0) [options] /path/to/config-file

    Options:
        -o, --outdir   : Output directory instead of (--rootfs-mnt alias can be passed 
            to use \$rootfs_mnt variable within the configuration. 
        --backup       : Backup existing file in case of a conflict (default: throw error)
        --update       : Overwrite existing file in case of a conflict (default: throw error)

HELP
}

die(){
    echo
    echo "$@"
    echo
    show_help
    exit 1
}

err(){
    echo "ERROR: $@"
    exit 1
}


# Parse command line arguments
# ---------------------------
# Initialize parameters
config_file=
outdir=
conflict="undefined"
# ---------------------------
args_backup=("$@")
args=()
_count=1
while :; do
    key="${1:-}"
    case $key in
        -h|-\?|--help|'')
            show_help    # Display a usage synopsis.
            exit
            ;;
        # --------------------------------------------------------
        -o|--outdir) shift
            outdir="$1"
            ;;
        --backup) 
            conflict="backup"
            ;;
        --update)
            conflict="update"
            ;;
        # --------------------------------------------------------
        -*) # Handle unrecognized options
            die "Unknown option: $1"
            ;;
        *)  # Generate the new positional arguments: $arg1, $arg2, ... and ${args[@]}
            if [[ ! -z ${1:-} ]]; then
                declare arg$((_count++))="$1"
                args+=("$1")
            fi
            ;;
    esac
    shift
    [[ -z ${1:-} ]] && break
done; set -- "${args_backup[@]}"
# Use $arg1 in place of $1, $arg2 in place of $2 and so on, 
# "$@" is in the original state,
# use ${args[@]} for new positional arguments  

config_file=${arg1:-}
[[ -f $config_file ]] \
    || die "Configuration file is required." \
    && config_file=$(realpath $config_file)
. $config_file

# Output directory
if [[ "$outdir" == "--rootfs-mnt" ]]; then
    outdir=$rootfs_mnt
else
    outdir=$(realpath "$outdir")
fi
echo "Outdir is set to: $outdir"
[[ -d $outdir ]] || err "--outdir must be a directory."
[[ -w $outdir ]] || err "Output directory ($outdir) is not writable."

TEMPLATER="$_sdir/bash-templater/templater.sh"
_ext=".$(timestamp).bak" # backup extension
cd $_sdir
while read -r template; do
    target="$outdir/${template#*/}"
    if [[ ! -d $(dirname $target) ]]; then
        echo "Creating $(dirname $target)"
        mkdir -p $(dirname $target)
    fi
    _target="${target#$(dirname $outdir)/}" # relative representation
    echo -n "Creating $_target: "
    if [[ -f $target ]]; then
        case $conflict in 
            undefined)
                echo "ERROR: File exists. (consider --update or --backup parameters)"
                exit 1
                ;;
            backup)
                mv "${target}" "${target}.${_ext}"
                echo "OK (Backed up the current one with ${_ext} extension)"
                ;;
            update)
                echo "OK (Updated)"
                ;;
            *)
                echo "You should never see this."
                exit 55
        esac
    else
        echo "OK"
    fi
    $TEMPLATER -f $config_file --nounset $template > $target
    chmod $(get_file_permissions $template) $target
done <<< $(find scripts.d -type f)
