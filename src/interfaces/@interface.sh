import reflection.sh
import util/utility.sh


@interface() {
    annotated_type "${1:-}" && local type="${1}" || return 1
    trigger "${2:-}" && local trigger="${2}" || return 1

    local get_annotated_target
    local annotation_target
    local listener
    local source_file="$(realpath "${BASH_SOURCE[1]}")"

    if [[ "${type}" == "function" ]]; then
        get_annotated_target="get_annotated_function" 
        if [[ "${trigger}" == "pre" ]]; then
            listener="invoke_function_annotation_pre \$annotated_function"
        elif [[ "${trigger}" == "post" ]]; then
            listener="invoke_function_annotation_post \$annotated_function"
        elif [[ "${trigger}" == "prepost" ]]; then
            listener="invoke_function_annotation_pre \$annotated_function || invoke_function_annotation_post \$annotated_function"
        fi
    elif [[ "${type}" == "variable" ]]; then
        :         
    fi

    annotation_target="$(${get_annotated_target} "${source_file}")"
    if [[ -n "${annotation_target}" ]]; then

        if [[ "${type}" == "function" ]]; then
            
            local function_body
            get_annotated_function_body "function_body" "${source_file}"
            if [[ -n "${function_body}" ]]; then
                { builtin source /dev/fd/999 ; } 999<<-DECLARE_ANNOTATION_FUNCTION 
                @${annotation_target}() {
                    local function_namespace="\${FUNCNAME[0]}_\${BASH_LINENO[0]}"
                    local source_file="$(realpath "\${BASH_SOURCE[1]}")"
                    local annotated_function="\$(get_annotated_function "\${source_file}")"

                    if [[ -n "\${annotated_function}" ]]; then

                        { builtin source /dev/fd/999 ; } 999<<-DECLARE_NAMESPACE_FUNCTION
                        \${function_namespace}() {
                            if ${listener}; then
                                ${function_body}
                            fi
                        }
DECLARE_NAMESPACE_FUNCTION
                        BASH_ANNOTATIONS_FUNCTION_ARRAY+=("\${function_namespace}")
                    else
                        return 1
                    fi
                }
DECLARE_ANNOTATION_FUNCTION
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


annotated_type() {
    local type="${1}"

    case "${type}" in
        "function")
            return 0
        ;;
        "variable")
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
        "pre")
            return 0
        ;;
        "post")
            return 0 
        ;;
        "prepost")
            return 0 
        ;;
        *)
            return 1 
        ;;
    esac
}
