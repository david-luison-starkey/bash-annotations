
get_variable_type() {
    local variable="${1}"
    local type_assertion="${2}"
    local type_signature="$(declare -p "${variable}" 2> /dev/null)"

    if [[ "${type_signature}" =~ "--" ]] && [[ "${type_assertion}" == "STRING" ]]; then
        return 0 
    elif [[ "$type_signature" =~ "-a" ]] && [[ "${type_assertion}" == "ARRAY" ]]; then
        return 0 
    elif [[ "$type_signature" =~ "-A" ]] && [[ "${type_assertion}" == "ASSOCIATIVE" ]]; then
        return 0 
    elif [[ "$type_signature" =~ "-i" ]] && [[ "${type_assertion}" == "INTEGER" ]]; then
        return 0 
    elif [[ "$type_signature" =~ "-n" ]] && [[ "${type_assertion}" == "NAMEREF" ]]; then
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

    if [[ "${type_signature}" == "alias" ]] && [[ "${type_assertion}" == "ALIAS" ]]; then
        return 0
    elif [[ "${type_signature}" == "keyword" ]] && [[ "${type_assertion}" == "KEYWORD" ]]; then
        return 0
    elif [[ "${type_signature}" == "function" ]] && [[ "${type_assertion}" == "FUNCTION" ]]; then
        return 0
    elif [[ "${type_signature}" == "builtin" ]] && [[ "${type_assertion}" == "BUILTIN" ]]; then
        return 0
    elif [[ "${type_signature}" == "file" ]] && [[ "${type_assertion}" == "FILE" ]]; then
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
