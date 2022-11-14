import reflection.bash
import util/utility.bash


@interface() {
    annotated_type "${1:-}" && local type="${1}" || return 1
    trigger "${2:-}" && local trigger="${2}" || return 1

    local annotation_target
    local source_file="$(realpath "${BASH_SOURCE[1]}")"

    annotation_target="$(get_annotated_function "${source_file}")"
    if [[ -n "${annotation_target}" ]]; then

        local function_body
        get_annotated_function_body "function_body" "${source_file}"

        if [[ -n "${function_body}" ]]; then
                
            if [[ "${type}" == "FUNCTION" ]]; then

                if [[ "${trigger}" == "PRE" ]]; then
                    
                    _build_function_annotation_pre "${annotation_target}" "${function_body}"

                elif [[ "${trigger}" == "POST" ]]; then

                    _build_function_annotation_post "${annotation_target}" "${function_body}"

                elif [[ "${trigger}" == "PREPOST" ]]; then
                
                    _build_function_annotation_prepost "${annotation_target}" "${function_body}"
                
                fi
        
            elif [[ "${type}" == "VARIABLE" ]]; then

                if [[ "${trigger}" == "PRE" ]]; then

                    _build_variable_annotation_pre "${annotation_target}" "${function_body}"

                elif [[ "${trigger}" == "POST" ]]; then

                    _build_variable_annotation_post "${annotation_target}" "${function_body}"

                elif [[ "${trigger}" == "PREPOST" ]]; then

                    _build_variable_annotation_prepost "${annotation_target}" "${function_body}"

                fi

            else
                return 1
            fi
        else
            return 1        
        fi
    else
        return 1
    fi
}


_build_function_annotation_pre() {
    local annotation_target="${1}" 
    local function_body="${2}"    

    { builtin source /dev/fd/999 ; } 999<<-DECLARE_FUNCTION_ANNOTATION_PRE 
    @${annotation_target}() {
        local function_namespace="\${FUNCNAME[0]}_\${BASH_LINENO[0]}"
        local source_file="$(realpath "\${BASH_SOURCE[1]}")"
        local annotated_function="\$(get_annotated_function "\${source_file}")"

        eval "declare -gx \${function_namespace#@*}_pre=false"

        if [[ -n "\${annotated_function}" ]]; then

            { builtin source /dev/fd/999 ; } 999<<-DECLARE_FUNCTION_ANNOTATION_NAMESPACE_PRE
            \${function_namespace}() {
                local inside_annotated_function_pre=\${function_namespace#@*}_pre

                if invoke_function_annotation_pre \$annotated_function && \
                [[ \\\${!inside_annotated_function_pre} == "false" ]]; then
                    eval "\${function_namespace#@*}_pre=true"
                    ${function_body}
                elif ! invoke_function_annotation_pre \$annotated_function && \
                [[ \\\${!inside_annotated_function_pre} == "true" ]] && \
                ! is_element_in_array \$annotated_function \\\${FUNCNAME[@]}; then
                    eval "\${function_namespace#@*}_pre=false"
                fi
            }
DECLARE_FUNCTION_ANNOTATION_NAMESPACE_PRE
            BASH_ANNOTATIONS_FUNCTION_ARRAY+=("\${function_namespace}")
        else
            return 1
        fi
    }
DECLARE_FUNCTION_ANNOTATION_PRE
}


_build_function_annotation_post() {
    local annotation_target="${1}" 
    local function_body="${2}"   

    { builtin source /dev/fd/999 ; } 999<<-DECLARE_FUNCTION_ANNOTATION_POST
    @${annotation_target}() {
        local function_namespace="\${FUNCNAME[0]}_\${BASH_LINENO[0]}"
        local source_file="$(realpath "\${BASH_SOURCE[1]}")"
        local annotated_function="\$(get_annotated_function "\${source_file}")"

        eval "declare -gx \${function_namespace#@*}_post=false"

        if [[ -n "\${annotated_function}" ]]; then

            { builtin source /dev/fd/999 ; } 999<<-DECLARE_FUNCTION_NAMESPACE_ANNOTATION_POST
            \${function_namespace}() {
                local inside_annotated_function_post=\${function_namespace#@*}_post

                if invoke_function_annotation_post \$annotated_function && \
                [[ \\\${!inside_annotated_function_post} == "false" ]]; then
                    eval "\${function_namespace#@*}_post=true"
                    ${function_body}
                elif ! invoke_function_annotation_post \$annotated_function && \
                [[ \\\${!inside_annotated_function_post} == "true" ]]; then
                    eval "\${function_namespace#@*}_post=false"
                fi
            }
DECLARE_FUNCTION_NAMESPACE_ANNOTATION_POST
            BASH_ANNOTATIONS_FUNCTION_ARRAY+=("\${function_namespace}")
        else
            return 1
        fi
    }
DECLARE_FUNCTION_ANNOTATION_POST
}


_build_function_annotation_prepost() {
    local annotation_target="${1}" 
    local function_body="${2}"   

    { builtin source /dev/fd/999 ; } 999<<-DECLARE_FUNCTION_ANNOTATION_PREPOST 
    @${annotation_target}() {
        local function_namespace="\${FUNCNAME[0]}_\${BASH_LINENO[0]}"
        local source_file="$(realpath "\${BASH_SOURCE[1]}")"
        local annotated_function="\$(get_annotated_function "\${source_file}")"

        eval "declare -gx \${function_namespace#@*}_pre=false"
        eval "declare -gx \${function_namespace#@*}_post=false"

        if [[ -n "\${annotated_function}" ]]; then

            { builtin source /dev/fd/999 ; } 999<<-DECLARE_FUNCTION_ANNOTATION_NAMESPACE_PREPOST
            \${function_namespace}() {
                local inside_annotated_function_pre=\${function_namespace#@*}_pre
                local inside_annotated_function_post=\${function_namespace#@*}_post

                if invoke_function_annotation_post \$annotated_function && \
                [[ \\\${!inside_annotated_function_post} == "false" ]]; then
                    eval "\${function_namespace#@*}_post=true"
                    ${function_body}
                elif ! invoke_function_annotation_post \$annotated_function && \
                [[ \\\${!inside_annotated_function_post} == "true" ]]; then
                    eval "\${function_namespace#@*}_post=false"
                fi

                if invoke_function_annotation_pre \$annotated_function && \
                [[ \\\${!inside_annotated_function_pre} == "false" ]]; then
                    eval "\${function_namespace#@*}_pre=true"
                    ${function_body}
                elif ! invoke_function_annotation_pre \$annotated_function && \
                [[ \\\${!inside_annotated_function_pre} == "true" ]] && \
                ! is_element_in_array \$annotated_function \\\${FUNCNAME[@]}; then
                    eval "\${function_namespace#@*}_pre=false"
                fi
            }
DECLARE_FUNCTION_ANNOTATION_NAMESPACE_PREPOST
            BASH_ANNOTATIONS_FUNCTION_ARRAY+=("\${function_namespace}")
        else
            return 1
        fi
    }
DECLARE_FUNCTION_ANNOTATION_PREPOST
}


_build_variable_annotation_pre() {
    local annotation_target="${1}" 
    local function_body="${2}"  

    { builtin source /dev/fd/999 ; } 999<<-DECLARE_VARIABLE_ANNOTATION_PRE 
    @${annotation_target}() {
        local function_namespace="\${FUNCNAME[0]}_\${BASH_LINENO[0]}"
        local source_file="$(realpath "\${BASH_SOURCE[1]}")"
        local annotated_variable="\$(get_annotated_variable "\${source_file}")"

        if [[ -n "\${annotated_variable}" ]]; then

            { builtin source /dev/fd/999 ; } 999<<-DECLARE_VARIABLE_NAMESPACE_ANNOTATION_PRE
            \${function_namespace}() {
                if invoke_variable_annotation_pre \$annotated_variable; then
                    ${function_body}
                fi
            }
DECLARE_VARIABLE_NAMESPACE_ANNOTATION_PRE
            BASH_ANNOTATIONS_FUNCTION_ARRAY+=("\${function_namespace}")
        else
            return 1
        fi
    }
DECLARE_VARIABLE_ANNOTATION_PRE
}


_build_variable_annotation_post() {
    local annotation_target="${1}" 
    local function_body="${2}"  

    { builtin source /dev/fd/999 ; } 999<<-DECLARE_VARIABLE_ANNOTATION_POST 
    @${annotation_target}() {
        local function_namespace="\${FUNCNAME[0]}_\${BASH_LINENO[0]}"
        local source_file="$(realpath "\${BASH_SOURCE[1]}")"
        local annotated_variable="\$(get_annotated_variable "\${source_file}")"

        eval "declare -gx \${function_namespace#@*}_post=false"

        if [[ -n "\${annotated_variable}" ]]; then

            { builtin source /dev/fd/999 ; } 999<<-DECLARE_VARIABLE_NAMESPACE_ANNOTATION_POST
            \${function_namespace}() {

                local annotated_variable_post_delayed_trigger=\${function_namespace#@*}_post

                if invoke_variable_annotation_pre \$annotated_variable && \
                [[ \\\${!annotated_variable_post_delayed_trigger} == "false" ]]; then
                    eval "\${function_namespace#@*}_post=true"
                elif ! invoke_variable_annotation_pre \$annotated_variable && \
                [[ \\\${!annotated_variable_post_delayed_trigger} == "true" ]]; then
                    eval "\${function_namespace#@*}_post=false"
                    ${function_body}
                fi
            }
DECLARE_VARIABLE_NAMESPACE_ANNOTATION_POST
            BASH_ANNOTATIONS_FUNCTION_ARRAY+=("\${function_namespace}")
        else
            return 1
        fi
    }
DECLARE_VARIABLE_ANNOTATION_POST
}



_build_variable_annotation_prepost() {
    local annotation_target="${1}" 
    local function_body="${2}"  

    { builtin source /dev/fd/999 ; } 999<<-DECLARE_VARIABLE_ANNOTATION_PREPOST 
    @${annotation_target}() {
        local function_namespace="\${FUNCNAME[0]}_\${BASH_LINENO[0]}"
        local source_file="$(realpath "\${BASH_SOURCE[1]}")"
        local annotated_variable="\$(get_annotated_variable "\${source_file}")"

        eval "declare -gx \${function_namespace#@*}_post=false"

        if [[ -n "\${annotated_variable}" ]]; then

            { builtin source /dev/fd/999 ; } 999<<-DECLARE_VARIABLE_NAMESPACE_ANNOTATION_PREPOST
            \${function_namespace}() {

                local annotated_variable_post_delayed_trigger=\${function_namespace#@*}_post

                if invoke_variable_annotation_pre \$annotated_variable && \
                [[ \\\${!annotated_variable_post_delayed_trigger} == "false" ]]; then
                    eval "\${function_namespace#@*}_post=true"
                    ${function_body}
                elif invoke_variable_annotation_pre \$annotated_variable && \
                [[ \\\${!annotated_variable_post_delayed_trigger} == "true" ]]; then
                    ${function_body}
                elif ! invoke_variable_annotation_pre \$annotated_variable && \
                [[ \\\${!annotated_variable_post_delayed_trigger} == "true" ]]; then
                    eval "\${function_namespace#@*}_post=false"
                    ${function_body}
                fi
            }
DECLARE_VARIABLE_NAMESPACE_ANNOTATION_PREPOST
            BASH_ANNOTATIONS_FUNCTION_ARRAY+=("\${function_namespace}")
        else
            return 1
        fi
    }
DECLARE_VARIABLE_ANNOTATION_PREPOST
}


annotated_type() {
    local type="${1}"

    case "${type}" in
        "FUNCTION")
            return 0
        ;;
        "VARIABLE")
            return 0 
        ;;
        *)
            return 1 
        ;;
    esac
}


trigger() {
    local trigger="${1}"

    case "${trigger}" in
        "PRE")
            return 0
        ;;
        "POST")
            return 0 
        ;;
        "PREPOST")
            return 0 
        ;;
        *)
            return 1 
        ;;
    esac
}
