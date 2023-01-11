import util/utility.bash

# Functions in reflection.bash are intended to be called only by interface functions.

get_annotated_function() {
    local source_file="${1:-${0}}"
    local annotation="${FUNCNAME[1]}"
    local annotation_length="${#annotation}"
    local line_start="${BASH_LINENO[1]}"
    local counter=0
    local start=false
    local function_pattern="^\s*[a-zA-Z:./_-]+\s*\(\)\s*\{$"
    local annotations_pattern="^\s*@[a-zA-Z:./_-]+\s*.*[\r\n]?$"
    local comment_pattern="^\s*#.*$"

    while IFS= read -r line; do
        ((counter++))
        line="$(trim "${line}")"
        if [[ $counter -eq $line_start ]] && [[ "${line:0:${annotation_length}}" == "${annotation}" ]]; then
            start=true
            continue
        fi
        if [[ "${line}" =~ $function_pattern ]] && [[ "${start}" == "true" ]]; then
            match="$(trim "${line}")"
            echo "${match%(*}"
            return 0
        elif [[ "${line}" =~ $annotations_pattern ]] || [[ "${line}" =~ $comment_pattern ]] && [[ "${start}" == "true" ]]; then
            continue
        elif [[ ! "${line}" =~ $annotations_pattern ]] && [[ "${start}" == "true" ]]; then
            return 1
        else
            continue
        fi
    done <"${source_file}"
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
    local end_of_function_pattern="^\s*\}\s*$"
    local annotations_pattern="^\s*@[a-zA-Z:./_-]+\s*.*[\r\n]?$"
    local comment_pattern="^\s*#.*$"

    while IFS= read -r line; do
        ((counter++))
        line="$(trim "${line}")"
        if [[ $counter -eq $line_start ]] && [[ "${line:0:${annotation_length}}" == "${annotation}" ]]; then
            start=true
            continue
        fi
        if [[ "${line}" =~ $function_pattern ]] && [[ "${start}" == "true" ]]; then
            parse_body=true
        elif [[ "${line}" =~ $annotations_pattern ]] || [[ "${line}" =~ $comment_pattern ]] && [[ "${start}" == "true" ]]; then
            continue
        elif [[ "${start}" == "true" ]] && [[ "${parse_body}" == "true" ]]; then
            if [[ "${line}" =~ $end_of_function_pattern ]]; then break; fi
            function_body_array+=("${line}")
        elif [[ ! "${line}" =~ $annotations_pattern ]] && [[ "${start}" == "true" ]] && [[ "${parse_body}" == "false" ]]; then
            return 1
        else
            continue
        fi
    done <"${source_file}"

    build_annotated_function_body_string function_body_string "${function_body_array[@]}"
}

build_annotated_function_body_string() {
    local -n nameref_function_body_string="${1}"
    shift
    local -a function_body_array=("${@}")

    # Reseved variable patterns that are not escaped (as with other variables used in a function).
    # This allows functions to leverage bash-annotations specific variables
    #
    # @interface special variables
    local reserved_namespace_annotated_function="\$annotated_function"
    local reserved_namespace_annotated_function_braces="\${annotated_function}"
    local reserved_namespace_annotated_variable="\$annotated_variable"
    local reserved_namespace_annotated_variable_braces="\${annotated_variable}"
    # @inject special variables
    local reserved_namespace_inject_annotated_function="\$inject_annotated_function"
    local reserved_namespace_inject_annotated_function_braces="\${inject_annotated_function}"

    # Argument variables are not escaped to allow new annotations to be declared with parameters
    # Pattern matching variables must be unquoted to function correctly
    local positional_parameters_pattern="\$[1-9]"
    local positional_parameters_pattern_braces="\${[1-9]"
    local array_parameter_pattern="\$@"
    local array_parameter_pattern_braces="\${@"

    for line in "${function_body_array[@]}"; do
        # Interface function making call to reflection.bash is twice removed from current function,
        # e.g. [0] build_annotated_function_body_string [1] get_annotated-function_body [2] @interface or @inject
        # affording more modularity
        if [[ "${FUNCNAME[2]}" == "@inject" ]]; then

            if [[ "${line}" == *"${reserved_namespace_inject_annotated_function}"* ]] ||
                [[ "${line}" == *"${reserved_namespace_inject_annotated_function_braces}"* ]] ||
                [[ "${line}" == *${positional_parameters_pattern}* ]] ||
                [[ "${line}" == *${positional_parameters_pattern_braces}* ]] ||
                [[ "${line}" == *"${array_parameter_pattern}"* ]] ||
                [[ "${line}" == *"${array_parameter_pattern_braces}"* ]]; then
                nameref_function_body_string+="$(trim "${line}")"
            else
                nameref_function_body_string+="$(trim "${line//\$/\\\\\\$}")"
            fi

        elif [[ "${FUNCNAME[2]}" == "@interface" ]]; then

            if [[ "${line}" == *"${reserved_namespace_annotated_function}"* ]] ||
                [[ "${line}" == *"${reserved_namespace_annotated_function_braces}"* ]] ||
                [[ "${line}" == *"${reserved_namespace_annotated_variable}"* ]] ||
                [[ "${line}" == *"${reserved_namespace_annotated_variable_braces}"* ]] ||
                [[ "${line}" == *${positional_parameters_pattern}* ]] ||
                [[ "${line}" == *${positional_parameters_pattern_braces}* ]] ||
                [[ "${line}" == *"${array_parameter_pattern}"* ]] ||
                [[ "${line}" == *"${array_parameter_pattern_braces}"* ]]; then
                nameref_function_body_string+="$(trim "${line}")"
            else
                nameref_function_body_string+="$(trim "${line//\$/\\$}")"
            fi

        fi

        nameref_function_body_string+=$'\n'
    done
}

invoke_function_annotation_pre() {
    local target_function="${1}"
    local target_function_length="${#target_function}"
    local parse_command="$(trim "$(grep -oP "^${target_function}(?!\(\)\s\{)(\s|$)" <<<"${BASH_COMMAND}")")"

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
    local parse_function_invocation="$(trim "$(grep "${target_function}" <<<"${parse_history}" | grep -oP "^${target_function}(?!\(\)\s\{)(\s|$)")")"

    if [[ "${parse_history:0:${target_function_length}}" == "${parse_function_invocation}" ]]; then
        return 0
    else
        return 1
    fi
}

get_annotated_variable() {
    local source_file="${1:-${0}}"
    local annotation="${FUNCNAME[1]}"
    local annotation_length="${#annotation}"
    local line_start="${BASH_LINENO[1]}"
    local counter=0
    local start=false

    local initialisation_pattern="^\s*[a-zA-Z0-9_-]+="
    # -F -f -p flags not supported as usage extends beyond declaring and initialising variables
    local declaration_pattern="^(declare|local)\s*(-[gaAilnrtux]+)?\s*[a-zA-Z0-9_-]+\s*$"
    local declaration_initialisation_pattern="^(declare|local)\s*(-[gaAilnrtux]+)?\s*[a-zA-Z0-9_-]+="
    local annotations_pattern="^\s*@[a-zA-Z:./_-]+\s*.*[\r\n]?$"
    local comment_pattern="^\s*#.*$"

    while IFS= read -r line; do
        ((counter++))
        line="$(trim "${line}")"
        if [[ $counter -eq $line_start ]] && [[ "${line:0:${annotation_length}}" == "${annotation}" ]]; then
            start=true
            continue
        fi
        if [[ "${line}" =~ $initialisation_pattern ]] && [[ "${start}" == "true" ]]; then
            echo "${line%\=*}"
            return 0
        elif [[ "${line}" =~ $declaration_pattern ]] && [[ "${start}" == "true" ]]; then
            match="$(trim "${line}")"
            echo "${match##* }"
            return 0
        elif [[ "${line}" =~ $declaration_initialisation_pattern ]] && [[ "${start}" == "true" ]]; then
            match="$(trim "${line}")"
            match="${match##* }"
            match="${match%\=*}"
            echo "${match}"
            return 0
        elif [[ "${line}" =~ $annotations_pattern ]] || [[ "${line}" =~ $comment_pattern ]] && [[ "${start}" == "true" ]]; then
            continue
        # Annotated variable should be immediately after the annotation itself, comments excepted
        elif ((counter >= (line_start + 1))) && [[ "${start}" == "true" ]]; then
            return 1
        fi
    done <"${source_file}"
}

invoke_variable_annotation_pre() {
    local target_variable="${1}"

    if [[ "${BASH_COMMAND}" == *"\$${target_variable}"* ]] ||
        # Curly braces not closed to allow pattern matching on parameter expansions
        [[ "${BASH_COMMAND}" == *"\${${target_variable}"* ]] ||
        [[ "${BASH_COMMAND}" == *"\${${target_variable}[@]}"* ]] ||
        [[ "${BASH_COMMAND}" == *"\${${target_variable}[*]}"* ]]; then
        return 0
    else
        return 1
    fi
}

invoke_variable_annotation_post() {
    local target_variable="${1}"
    local parse_history="$(builtin history 2 | head -1 | sed 's/^ *[0-9]* *//')"

    if [[ "${parse_history}" == *"\$${target_variable}"* ]] ||
        # Curly braces not closed to allow pattern matching on parameter expansions
        [[ "${parse_history}" == *"\${${target_variable}"* ]] ||
        [[ "${parse_history}" == *"\${${target_variable}[@]}"* ]] ||
        [[ "${parse_history}" == *"\${${target_variable}[*]}"* ]]; then
        return 0
    else
        return 1
    fi
}
