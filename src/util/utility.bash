is_element_in_array() {
	local value="${1}"
	shift
	local array=("${@}")

	for item in "${array[@]}"; do
		[[ "${value}" == "${item}" ]] && return 0
	done

	return 1
}

remove_element_from_array() {
	local element_to_remove="${1}"
	local -n array="${2}"

	for i in "${!array[@]}"; do
		if [[ "${array[i]}" == "${element_to_remove}" ]]; then
			unset "array[i]"
		fi
	done
}

# https://stackoverflow.com/questions/369758/how-to-trim-whitespace-from-a-bash-variable/3352015#3352015
trim() {
	local to_trim="$1"

	to_trim="${to_trim#"${to_trim%%[![:space:]]*}"}"
	to_trim="${to_trim%"${to_trim##*[![:space:]]}"}"

	echo "${to_trim}"
}

# Function serves as a more reliable way of retrieving the value of "${annotated_variable}"
# as indirection (i.e. "${!annotated_variable}") has proven to be unreliable in some instances.
get_annotated_variable_value() {
	local variable="${1}"
	local variable_value="$(declare -p "${variable}" 2>/dev/null)"
	variable_value="${variable_value##*\=}"
	remove_double_quotes "${variable_value}"
}

# Remove leading and trailing double quotation marks from text
remove_double_quotes() {
	string="${1}"
	string="${string#*\"}"
	echo "${string%\"*}"
}

# Helper function to populate the passed array with all currently declared annotation functions
# i.e. functions that are prepended by an @ symbol
#
# Parameter 1: Array (nameref)
#
#
# Example:
#
# declare -a array
#
# return_declared_annotation_functions_array array
#
# echo "${array[*]}"
return_declared_annotation_functions_array() {
	local -n functions_array="${1}"
	read -a functions_array < <(declare -F | cut -d " " -f 3 | grep -oP "^@[a-zA-Z:./_-]+$" | grep -v "@interface" | grep -v "@inject" | tr '\n' ' ')
}
