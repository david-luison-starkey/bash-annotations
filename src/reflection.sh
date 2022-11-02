import util/utility.sh


get_annotated_function() {
    local source_file="${1:-${0}}"
    local annotation="${FUNCNAME[1]}"
    local annotation_length="${#annotation}"
    local line_start="${BASH_LINENO[1]}"
    local counter=0
    local start=false
    local function_pattern="^\s*[a-zA-Z:./_-]+\s*\(\)\s*\{$"
    local annotations_pattern="^\s*#*\s*@[a-zA-Z:./_-]+\s*.*[\r\n]?$"

    while IFS= read -r line; do
        ((counter++))
        if [[ $counter -eq $line_start ]] && [[ "${line:0:${annotation_length}}" == "${annotation}" ]]; then start=true; continue; fi
        if [[ "${line}" =~ $function_pattern ]] && [[ "${start}" == "true" ]]; then 
            echo "${line%(*}"
            return 0
        elif [[ "${line}" =~ $annotations_pattern ]] && [[ "${start}" == "true" ]]; then
            continue
        elif [[ ! "${line}" =~ $annotations_pattern ]] && [[  "${start}" == "true" ]] ; then
            return 1
        else
            continue
        fi
    done < "${source_file}"
} 


get_annotated_function_body() {
    local -n function_body_string="${1}"
    local -a function_body_array

    local source_file="${2:-${0}}"
    local annotation="${FUNCNAME[1]}"
    local annotation_length="${#annotation}"
    local line_start="${BASH_LINENO[1]}"
    local counter=0
    local start=false
    local parse_body=false
    local function_pattern="^\s*[a-zA-Z:./_-]+\s*\(\)\s*\{$"
    local annotations_pattern="^\s*#*\s*@[a-zA-Z:./_-]+\s*.*[\r\n]?$"
    local end_of_function_pattern="^\s*\}\s*$"
    local reserved_namespace_annotated_function="\${annotated_function}"

    while IFS= read -r line; do
        ((counter++))
        if [[ $counter -eq $line_start ]] && [[ "${line:0:${annotation_length}}" == "${annotation}" ]]; then start=true; continue; fi
        if [[ "${line}" =~ $function_pattern ]] && [[ "${start}" == "true" ]]; then 
            parse_body=true
        elif [[ "${line}" =~ $annotations_pattern ]] && [[ "${start}" == "true" ]]; then
            continue
        elif [[ "${start}" == "true" ]] && [[ "${parse_body}" == "true" ]]; then
            if [[ "${line}" =~ $end_of_function_pattern ]]; then break; fi
            function_body_array+=("${line}")
        elif [[ ! "${line}" =~ $annotations_pattern ]] && [[  "${start}" == "true" ]] && [[ "${parse_body}" == "false" ]] ; then
            return 1
        else
            continue
        fi
    done < "${source_file}" 

    for line in "${function_body_array[@]}"; do
        if [[ "${FUNCNAME[1]}" == "@inject" ]]; then
            function_body_string+="$(trim "${line//\$/\\\\\\$}")"
        elif [[ "${line}" =~ "${reserved_namespace_annotated_function}" ]]; then
            function_body_string+="$(trim "${line}")"
        else
            function_body_string+="$(trim "${line//\$/\\$}")"
        fi
        function_body_string+=$'\n'
    done
} 


invoke_function_annotation_pre() {
    local target_function="${1}" 
    local target_function_length="${#target_function}"
    local parse_command="$(grep -oP "^${target_function}(?!\(\)\s\{)" <<< "${BASH_COMMAND}")"

    if [[ "${parse_command:0:${target_function_length}}" == "${target_function}" ]]; then
        return 0
    else
        return 1
    fi
}


invoke_function_annotation_post() {
    local target_function="${1}"
    local target_function_length="${#target_function}"
    local parse_history="$(builtin history 2 | head -1 | sed 's/^ *[0-9]* *//')"
    local parse_function_invocation="$(grep "${target_function}" <<< "${parse_history}" | grep -oP "^${target_function}(?!\(\)\s\{)")"

    if [[ "${parse_history:0:${target_function_length}}" == "${parse_function_invocation}" ]]; then
        return 0
    else
        return 1
    fi
}


get_annotated_variable() {
    :
}


invoke_variable_annotation_pre() {
    :
}


invoke_variable_annotation_post() {
    :
}
