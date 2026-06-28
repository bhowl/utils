#!/bin/bash

set -e
# utils_sh is set in bashrc-like environment
# TODO: while IFS=$'\\n' read -r line; do snake_case "$line"; done < <(/bin/ls -1)
. $utils_sh/func.sh || exit 99

while (( $# > 0 )); do
	case "$1" in
		-h|--help)
			cat <<EOF
Usage: ${0##*/} [OPT]... SOURCE
Renames given file to "snake case" by converting all letters to lowercase and 
all spaces to underscores. Script will prompt before overwrite if filename 
already exists.
  -h, --help    Prints this help then exits
EOF
			exit
			;;
		*)
			break
			;;
	esac
done

# Positional Argument
filename="$1"
check_args 1 "$filename"

# Convert 'File name' to file_name
new="$( echo "$filename" | sed 's/ /_/g; s/\(.*\)/\L\1/')"
mv -b "$filename" "$new"

# Check success
if [[ -f "$new" ]]; then
	echo "$filename --> $new"
fi
