#!/bin/bash
set -eu

# Description:
# Finds the packages that are not depended by anyone in our system

unused=()
installed=$(./get-all-installed.sh)
while read i; do
    found=
    used_in=()
    echo "$installed" | grep -q -w "$i$" || continue
    while read dep; do
        [[ -z $dep ]] && continue
        if echo "$installed" | grep -q -w "$dep$"; then
            used_in+=("$dep")
            found="yes"
        fi
    done <<< $( ./apt-get-dependents.sh $i )
    if [[ -z $found ]]; then
        unused+=("$i")
    else
        echo "Using $i in: ${used_in[@]}"
    fi
done <<< $(echo $@ | tr ' ' '\n')

if [[ ${#unused[@]} -ne 0 ]]; then
    echo "Not used by anyone:"
    echo "${unused[@]}"
else
    echo "No unused packages found."
fi
