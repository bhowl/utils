#!/bin/bash
# A library of utility functions for bash scripting.

err_info() {
	echo -n "${BASH_SOURCE[$((${#BASH_SOURCE[@]} - 1))]##*/}: "
	for (( i=0; i < $(( ${#FUNCNAME[@]} - 1 )); i++ )); do
		echo -n "${FUNCNAME[$i]}(${BASH_LINENO[$i]}): "
	done
	echo "$*"
}

# Prints error info, then returns exit status of 1.
# @param      additional error message
# @returns    exit status
err_exit() {
	echo "$(err_info $*)" >&2
	exit 1
}


# Checks the exit status is 0 for previous command, else err_exit
# @returns exit status
check_for_zero_exit_status() {
	if (( "$?" != 0 )); then
		return "$?"
	fi
}

# Sources specifed file or returns
# @param    file to source
source_or_return()
{
	local file="$1"
	if [[ -f "$file" ]]; then
		. "$file"
	else
		err_info "Could not source ${file##*/}" && return 1
	fi
}

# Sources specified file or exits.
# @param    file to source
source_or_exit() {
	local file="$1"
	if [[ -f "$file" ]]; then
		. "$file" "${@:2}"
	else
		err_exit "Could not source ${file##*/}"
	fi
}

# Checks parameters given to script. Looks for one argument to be specified (or exits).
# @param    the script's parameters 
# TODO: add more functions for checking number of args, options vs tokens vs option w/ token
specify_arg() {
	if (( $# < 1 )); then
		err_info "Please specify arg" && return 1
	fi
}

# First checks number of required parameters. Then checks if "--help" or "-h" are provided as
# options to the script.
# @returns    err_exit if number of params are less than provided.
# @returns    export $helpOpt boolean
check_args() {
	local n="$1" # number of required params
	
	if (( $# < $(( $n + 1 )) )); then
		err_exit "A minimum of $n arg(s) are required ($#)"
	fi
	
	local reqParams=("${@:2:$n}")

	local i=0
	for (( i=0; i<${#reqParams[@]}; i++)); do
		if [[ -z "${reqParams[$i]}" ]]; then
			err_exit "specify arg: $(( i + 1 ))"
		fi
	done
}

# TODO: update 
positional_param1() {
	if [[ "$1" != -* ]]; then
		err_exit "First arg is a positional parameter"
	fi
}

# Checks the given path-to-directory exists.
# @param      path-to-directory
# @returns    exit status
check_path_exists() {
	local path="$1"
	if ! [[ -d "$path" ]] || [[ -z "$path" ]]; then
		return 1
	fi
}

# Checks the given path-to-directory exists.
# @param      path-to-directory
# @returns    exit status
check_file_exists() {
	local file="$1"
	if ! [[ -e "$file" ]] || [[ -z "$file" ]]; then
		return 1
	fi
}

# Prompts terminal for continuation response
# @input      from user
# @returns    exit status
continue_prompt() {
	echo -en "[PROMPT] Do you want to continue? (y/n)\t"
	read continue
	if [[ "$continue" == "y" ]]; then
		return 0
	elif [[ "$continue" == "n" ]]; then
		return 1
	else
		echo "Please respond with 'y' or 'n'."
		continue_prompt
	fi
}

# Prints array element per line.
# @param    a bash array
arr_cmd() {
	local cmd="$1"
	local arr=( "${@:2}" )
	for el in "${arr[@]}"; do
		eval $cmd "$el"
	done
}

arr_uniq() {
	local pattern="$1"
	local arr=("${@:2}")
	if (( ${#arr[@]} > 0 )); then
		for el in "${arr[@]}"; do
			if [[ "$el" == "$pattern" ]]; then
				echo true && return 0
			fi
		done
	else
		return 1
	fi

	echo false && return 0
}

# Function to find the most frequent string in an array
arr_most_freq_str() {
    local arr=("$@")
    declare -A count
    local maxCount=0
    export maxString=""
    local -a maxStrings
    export isTied=false

    # Count occurrences and track strings with maximum count
    for str in "${arr[@]}"; do
        ((count["$str"]++))
        if [ ${count["$str"]} -gt $maxCount ]; then
            maxCount=${count["$str"]}
            maxString="$str"
            maxStrings=("$str")
        elif [ ${count["$str"]} -eq $maxCount ]; then
            maxStrings+=("$str")
        fi
    done

    # Handle empty array
    if [ $maxCount -eq 0 ]; then
        return 1
    fi

    # Set isTied: true if multiple strings have max count or all counts are 1
    if [ ${#maxStrings[@]} -gt 1 ] || [ $maxCount -eq 1 ]; then		
        export isTied=true
    fi
    return 0
}

# TODO: update
mv_check() {
	# Only supports SOURCE to DEST (no -t option)
	local source="$1"
	local dest="$2"
	
	if (( $# != 2 )); then
		err_exit "specify 2 arguments"
	fi

	if ! readlink -e "$source" > /dev/null; then
		err_info "$source doesn't exist" && return 1
	fi

	if [[ -d "$dest" ]]; then
		echo "Moves $source in $dest directory"
	else
		echo  "Renames $source to $dest"
	fi
}

# Copies given array of files from source directory to given destination.
# @param    source (directory)
# @param    dest (directory)
# @param    array of files to be copied
copy_files_array_to_dest() {
	local exit_status=0;
	local source="$1"
	local dest="$2";
	local array=("${@:3}")
	
	for file in "${array[@]}"; do
		cp -fv $source/$file $dest
		wait
	done	
}

clean_directory() {
	local flagQuiet=false
	
	while (( $# > 0 )); do
		case "$1" in
			-q)
				flagQuiet=true
				shift
				;;
			*)
				break
				;;
			-*)
				err_exit "${FUNCNAME[0]}(): Unknown option: $1"
				;;
		esac
	done
    local dirPath="$1"	
	check_args 1 "$dirPath"
	
    # Validate input
    if [[ -z "$dirPath" || "$dirPath" == "/" || \
			  "$dirPath" == "/home" || "$dirPath" == "/etc" ]]; then
        err_exit "Invalid or dangerous path: $dirPath"
    fi

    # Check if path exists
    check_path_exists "$dirPath" || err_exit "Path doesn't exist: $dirPath"

    # Check if there are files or subdirectories to delete
    if compgen -G "$dirPath/*" > /dev/null; then
        $flagQuiet || echo "Cleaning directory: $dirPath"
        rm -rf "$dirPath/"* || err_exit "Failed cleaning $dirPath/*: $dirPath/*"
        $flagQuiet || echo "Deleted contents of $dirPath"
    fi
}

# Helper function for selecting from an array.
make_selection() {
	local array=();
	array=( "$@" );

    select selection in "${array[@]}" "DONE"; do
        if (( 1 <= "$REPLY" )) && \
			   (( "$REPLY" <= ${#array[@]} )); then
            break
		elif (( "$REPLY" == ${#array[@]} + 1 )); then
			break
        else
            echo "Select any number from 1-$(( ${#array[@]} + 1 ))"
        fi
    done
	export REPLY selection
}

# Prints recursively, given file's '# TODO:' comments in org-mode format
org_grep_todos() {
    local target="$1"

	grep -R -H -n -E '^[[:space:]]*# TODO:' "$target" |
		while IFS=: read -r file line rest; do
			todo=$(printf '%s\n' "$rest" |
					   sed -E 's/^[[:space:]]*# TODO:[[:space:]]*//')

        printf '** TODO %s\n' "$todo"
        printf '   [[file:%s::%s][%s:%s]]\n' \
               "$file" "$line" "$(basename "$file")" "$line"
    done	
}

# Adds non-duplicate path to `dirs` builtin directory stack (suppresses normal change of directory)
add_new_path_to_dir_stack() {
	local path="$1"
	check_args 1 "$path"
	
	pathFound=false
	for dir in $(dirs); do
		if [[ "$dir" == "$path" ]]; then
			pathFound=true;
			break
		fi
	done

	if ! $pathFound; then
		pushd -n "$path" > /dev/null
	fi
}

# Parses an ISO8601 timestamp into Unix epoch seconds via jq, not `date
# -d` (a GNU coreutils extension - unavailable on macOS's native BSD
# date). Handles a trailing Z, an explicit +HH:MM/-HH:MM offset, or
# neither; fractional seconds and a missing :SS are both optional.
# NOTE: jq's mktime ignores any offset parsed via %z (confirmed
# empirically), so the offset is stripped and applied manually
# afterward rather than trusted to strptime/mktime directly.
# @param    ISO8601 timestamp string
# @returns  epoch seconds on stdout
iso8601_to_epoch() {
	local iso="$1"
	check_args 1 "$iso"

	jq -n -r --arg d "$iso" '
	  ($d | sub("\\.[0-9]+"; "")) as $no_frac |
	  ( $no_frac | if test("Z$") then {naive: sub("Z$"; ""), offset: 0}
	    elif test("[+-][0-9]{2}:[0-9]{2}$") then
	      ($no_frac | capture("(?<body>.*)(?<sign>[+-])(?<hh>[0-9]{2}):(?<mm>[0-9]{2})$")) as $m |
	      ($m.hh|tonumber) as $hh |
	      ($m.mm|tonumber) as $mm |
	      (if $m.sign == "-" then -1 else 1 end) as $sign_mult |
	      {naive: $m.body, offset: (($hh*3600 + $mm*60) * $sign_mult)}
	    else {naive: $no_frac, offset: 0}
	    end
	  ) as $parts |
	  ($parts.naive |
	    if test("^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}$") then
	      strptime("%Y-%m-%dT%H:%M:%S")
	    else
	      strptime("%Y-%m-%dT%H:%M")
	    end | mktime
	  ) - $parts.offset
	'
}
