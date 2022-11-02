
get_variable_type() {
    local variable="${1}"
    local type_assertion="${2}"
    local type_signature="$(declare -p "${variable}" 2> /dev/null)"

    if [[ "${type_signature}" =~ "--" ]] && [[ "${type_assertion}" == "string" ]]; then
        return 0 
    elif [[ "$type_signature" =~ "-a" ]] && [[ "${type_assertion}" == "array" ]]; then
        return 0 
    elif [[ "$type_signature" =~ "-A" ]] && [[ "${type_assertion}" == "map" ]]; then
        return 0 
    elif [[ "$type_signature" =~ "-i" ]] && [[ "${type_assertion}" == "integer" ]]; then
        return 0 
    elif [[ "$type_signature" =~ "-n" ]] && [[ "${type_assertion}" == "nameref" ]]; then
        return 0
    elif [[ "$type_signature" =~ "-n" ]]; then
        local reference="${type_signature#*\"}"
        reference="${reference%\"*}"
        get_variable_type "${reference}" "${type_assertion}"
    else
        return 1
    fi
}


get_command_type() {
    local type="${1}" 
    local type_assertion="${2}"
    local type_signature=$(type -t "${type}")

    if [[ "${type_signature}" == "alias" ]] && [[ "${type_assertion}" == "alias" ]]; then
        return 0
    elif [[ "${type_signature}" == "keyword" ]] && [[ "${type_assertion}" == "keyword" ]]; then
        return 0
    elif [[ "${type_signature}" == "function" ]] && [[ "${type_assertion}" == "function" ]]; then
        return 0
    elif [[ "${type_signature}" == "builtin" ]] && [[ "${type_assertion}" == "builtin" ]]; then
        return 0
    elif [[ "${type_signature}" == "file" ]] && [[ "${type_assertion}" == "file" ]]; then
        return 0
    else
        return 1
    fi
}


get_type() {
    local type="${1}" 
    local type_assertion="${2}"

    get_variable_type "${type}" "${type_assertion}" || \
    get_command_type "${type}" "${type_assertion}" || \
    return 1
}
