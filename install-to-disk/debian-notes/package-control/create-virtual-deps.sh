#!/bin/bash
set -u
safe_source () { [[ ! -z ${1:-} ]] && source $1; _dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; _sdir=$(dirname "$(readlink -f "$0")"); }; safe_source

show_help(){
    cat <<HELP

    $(basename $0) --name package-name dep1 [dep2 ...]

HELP
}

die(){
    echo
    echo "$1"
    show_help
    exit 1
}

# Parse command line arguments
# ---------------------------
# Initialize parameters
name=
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
        --name|--for) shift
            name="${1:-}"
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

[[ -z ${name:-} ]] && die "Name is required."
[[ ${#args[@]} -eq 0 ]] && die "You should provide at least one dependency."
deps=("${args[@]}")

function join_by { local IFS="$1"; shift; echo "$*"; }

package_name="$name-deps"

# Following template can be created by `equivs-control my.control` command:
control=`cat<<EOL
### Commented entries have reasonable defaults.
### Uncomment to edit them.
# Source: <source package name; defaults to package name>
Section: misc
Priority: optional
# Homepage: <enter URL here; no default>
Standards-Version: 3.9.2

Package: $package_name
#Version: 1.0
# Maintainer: Your Name <yourname@example.com>
# Pre-Depends: <comma-separated list of packages>
Depends: $(join_by , "${deps[@]}")
# Recommends: <comma-separated list of packages>
# Suggests: <comma-separated list of packages>
# Provides: <comma-separated list of packages>
# Replaces: <comma-separated list of packages>
# Architecture: all
# Multi-Arch: <one of: foreign|same|allowed>
# Copyright: <copyright file; defaults to GPL2>
# Changelog: <changelog file; defaults to a generic changelog>
# Readme: <README.Debian file; defaults to a generic one>
# Extra-Files: <comma-separated list of additional files for the doc directory>
# Links: <pair of space-separated paths; First is path symlink points at, second is filename of link>
# Files: <pair of space-separated paths; First is file to include, second is destination>
#  <more pairs, if there's more than one file to include. Notice the starting space>
Description:
 A virtual package that declares $name dependencies. 
EOL
`

equivs-build <( echo "$control" )
[[ $? -eq 0 ]] || exit 1
echo
echo "Use the following command to install this package:"
echo
echo "    sudo apt install ./${package_name}_1.0_all.deb"
echo
