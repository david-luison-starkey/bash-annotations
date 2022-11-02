
is_element_in_array() {
    local value="${1}"; shift;
    local array=("${@}")

    for item in "${array[@]}"; do
        [[ "${value}" == "${item}" ]] && return 0
    done

    return 1
}


remove_element_from_array() {
    local remove="${1}"
    local -n array="${2}"

    for i in "${!array[@]}"; do
        if [[ "${array[i]}" == "${remove}" ]]; then
            unset "array[i]"
        fi
    done
}

# https://stackoverflow.com/questions/369758/how-to-trim-whitespace-from-a-bash-variable/3352015#3352015
trim() {
    local var="$1"

    var="${var#"${var%%[![:space:]]*}"}"
    var="${var%"${var##*[![:space:]]}"}"

    echo "${var}"
}


return_declared_annotation_functions_array() {
    local -n functions_array="${1}"
    read -a functions_array < <(declare -F | cut -d " " -f 3 | grep -oP "^@[a-zA-Z:./_-]+$" | tr '\n' ' ')
}
