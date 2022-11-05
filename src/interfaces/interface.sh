import reflection.sh
import util/utility.sh


@interface() {
    annotated_type "${1:-}" && local type="${1}" || return 1
    trigger "${2:-}" && local trigger="${2}" || return 1

    local get_annotated_target
    local annotation_target
    local source_file="$(realpath "${BASH_SOURCE[1]}")"

    if [[ "${type}" == "FUNCTION" ]]; then
        get_annotated_target="get_annotated_function" 
    elif [[ "${type}" == "VARIABLE" ]]; then
        : # TODO: variable stuff        
    fi

    annotation_target="$(${get_annotated_target} "${source_file}")"
    if [[ -n "${annotation_target}" ]]; then

        if [[ "${type}" == "FUNCTION" ]]; then
            
            local function_body
            get_annotated_function_body "function_body" "${source_file}"

            if [[ -n "${function_body}" ]]; then
                
                if [[ "${trigger}" == "PRE" ]]; then
                    
                    _build_function_pre "${annotation_target}" "${function_body}"

                elif [[ "${trigger}" == "POST" ]]; then

                    _build_function_post "${annotation_target}" "${function_body}"

                elif [[ "${trigger}" == "PREPOST" ]]; then
                
                    _build_function_prepost "${annotation_target}" "${function_body}"
                
                fi
            else
                return 1
            fi
        else
            : # TODO: variable stuff
        fi
    else
        return 1
    fi
}


_build_function_pre() {
    local annotation_target="${1}" 
    local function_body="${2}"    

    { builtin source /dev/fd/999 ; } 999<<-DECLARE_ANNOTATION_FUNCTION_PRE 
    @${annotation_target}() {
        local function_namespace="\${FUNCNAME[0]}_\${BASH_LINENO[0]}"
        local source_file="$(realpath "\${BASH_SOURCE[1]}")"
        local annotated_function="\$(get_annotated_function "\${source_file}")"

        eval "declare -gx \${function_namespace#@*}_pre=false"

        if [[ -n "\${annotated_function}" ]]; then

            { builtin source /dev/fd/999 ; } 999<<-DECLARE_NAMESPACE_FUNCTION_PRE
            \${function_namespace}() {
                local inside_namespace_function_pre=\${function_namespace#@*}_pre

                if invoke_function_annotation_pre \$annotated_function && \
                [[ \\\${!inside_namespace_function_pre} == "false" ]]; then
                    eval "\${function_namespace#@*}_pre=true"
                    ${function_body}
                elif ! invoke_function_annotation_pre \$annotated_function && \
                [[ \\\${!inside_namespace_function_pre} == "true" ]] && \
                ! is_element_in_array \$annotated_function \\\${FUNCNAME[@]}; then
                    eval "\${function_namespace#@*}_pre=false"
                fi
            }
DECLARE_NAMESPACE_FUNCTION_PRE
            BASH_ANNOTATIONS_FUNCTION_ARRAY+=("\${function_namespace}")
        else
            return 1
        fi
    }
DECLARE_ANNOTATION_FUNCTION_PRE
}


_build_function_post() {
    local annotation_target="${1}" 
    local function_body="${2}"   

    { builtin source /dev/fd/999 ; } 999<<-DECLARE_ANNOTATION_FUNCTION_POST
    @${annotation_target}() {
        local function_namespace="\${FUNCNAME[0]}_\${BASH_LINENO[0]}"
        local source_file="$(realpath "\${BASH_SOURCE[1]}")"
        local annotated_function="\$(get_annotated_function "\${source_file}")"

        eval "declare -gx \${function_namespace#@*}_post=false"

        if [[ -n "\${annotated_function}" ]]; then

            { builtin source /dev/fd/999 ; } 999<<-DECLARE_NAMESPACE_FUNCTION_POST
            \${function_namespace}() {
                local inside_namespace_function_post=\${function_namespace#@*}_post

                if invoke_function_annotation_post \$annotated_function && \
                [[ \\\${!inside_namespace_function_post} == "false" ]]; then
                    eval "\${function_namespace#@*}_post=true"
                    ${function_body}
                elif ! invoke_function_annotation_post \$annotated_function && \
                [[ \\\${!inside_namespace_function_post} == "true" ]]; then
                    eval "\${function_namespace#@*}_post=false"
                fi
            }
DECLARE_NAMESPACE_FUNCTION_POST
            BASH_ANNOTATIONS_FUNCTION_ARRAY+=("\${function_namespace}")
        else
            return 1
        fi
    }
DECLARE_ANNOTATION_FUNCTION_POST
}


_build_function_prepost() {
    local annotation_target="${1}" 
    local function_body="${2}"   

    { builtin source /dev/fd/999 ; } 999<<-DECLARE_ANNOTATION_FUNCTION_PREPOST 
    @${annotation_target}() {
        local function_namespace="\${FUNCNAME[0]}_\${BASH_LINENO[0]}"
        local source_file="$(realpath "\${BASH_SOURCE[1]}")"
        local annotated_function="\$(get_annotated_function "\${source_file}")"

        eval "declare -gx \${function_namespace#@*}_pre=false"
        eval "declare -gx \${function_namespace#@*}_post=false"

        if [[ -n "\${annotated_function}" ]]; then

            { builtin source /dev/fd/999 ; } 999<<-DECLARE_NAMESPACE_FUNCTION_PREPOST
            \${function_namespace}() {
                local inside_namespace_function_pre=\${function_namespace#@*}_pre
                local inside_namespace_function_post=\${function_namespace#@*}_post

                if invoke_function_annotation_post \$annotated_function && \
                [[ \\\${!inside_namespace_function_post} == "false" ]]; then
                    eval "\${function_namespace#@*}_post=true"
                    ${function_body}
                elif ! invoke_function_annotation_post \$annotated_function && \
                [[ \\\${!inside_namespace_function_post} == "true" ]]; then
                    eval "\${function_namespace#@*}_post=false"
                fi

                if invoke_function_annotation_pre \$annotated_function && \
                [[ \\\${!inside_namespace_function_pre} == "false" ]]; then
                    eval "\${function_namespace#@*}_pre=true"
                    ${function_body}
                elif ! invoke_function_annotation_pre \$annotated_function && \
                [[ \\\${!inside_namespace_function_pre} == "true" ]] && \
                ! is_element_in_array \$annotated_function \\\${FUNCNAME[@]}; then
                    eval "\${function_namespace#@*}_pre=false"
                fi
            }
DECLARE_NAMESPACE_FUNCTION_PREPOST
            BASH_ANNOTATIONS_FUNCTION_ARRAY+=("\${function_namespace}")
        else
            return 1
        fi
    }
DECLARE_ANNOTATION_FUNCTION_PREPOST
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
