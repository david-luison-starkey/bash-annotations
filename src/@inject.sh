import reflection.sh
import utility.sh


@inject() {
    local remove="remove_element_from_array \${function_namespace} BASH_ANNOTATIONS_FUNCTION_ARRAY"
    local listener="invoke_function_annotation_pre \$annotated_function"
    local source_file="$(realpath "${BASH_SOURCE[1]}")"
    local annotated_function="$(get_annotated_function "${source_file}")"

    if [[ -n "${annotated_function}" ]]; then
        local function_body 
        get_annotated_function_body "function_body" "${source_file}"

        if [[ -n "${function_body}" ]]; then

            { source /dev/fd/999 ; } 999<<-DECLARE_ANNOTATION_FUNCTION
            @${annotated_function}() {
                local function_namespace="\${FUNCNAME[0]}_\${BASH_LINENO[0]}"
                local source_file="\$(realpath "\${BASH_SOURCE[1]}")"
                local injection_annotated_function="\$(get_annotated_function "\${source_file}")"

                if [[ -n "\${injection_annotated_function}" ]]; then

                    { builtin source /dev/fd/999 ; } 999<<-DECLARE_NAMESPACE_FUNCTION
                        \${function_namespace}() {
                            if ${listener}; then
                                func_body=\\\$(declare -f \$injection_annotated_function)
                                func_body="\\\${func_body#*{}"
                                func_body="\\\${func_body%\}}"

                                { builtin source /dev/fd/999 ; } 999<<-DECLARE_INJECTED_FUNCTION
                                \${injection_annotated_function}() {
                                    ${function_body}
                                    \\\${func_body}
                                }
DECLARE_INJECTED_FUNCTION
                            ${remove}
                            fi
                        }
DECLARE_NAMESPACE_FUNCTION
                        BASH_ANNOTATIONS_FUNCTION_ARRAY+=("\${function_namespace}")
                else
                    return 1
                fi
            }
DECLARE_ANNOTATION_FUNCTION
        fi
    fi
}
