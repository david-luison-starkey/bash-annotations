import reflection.bash
import util/utility.bash


# @inject interface function.
# Declares an annotation version of the function that it annotates.
# This newly created function (declared at runtime) has the ability to detect
# the function that it annotates. 
#
# Once detected, a function unique to the annotated function is added to 
# BASH_ANNOTATIONS_FUNCTION_ARRAY.
#
# The annotated function's invocation is listened for (via the DEBUG trap).
# Once invocation is detected, the annotated function is re-declared prior
# to running, with the body of the created injection annotation being injected
# in the requeted location.
#
# Once injection has been completed, the unique function is consumed (i.e. 
# removed from the BASH_ANNOTATIONS_FUNCTION_ARRAY). 
#
# Due to its non-persistent nature, @inject is significantly less resource 
# intensive than @interface created annotations that target functions. 
#
# Parameter 1: Injection location 
#
# Valid values: PRE, POST, PREPOST (case-sensitive)
@inject() {
    local location
    injection_location "${1:-}" && local location="${1}" || return 1
    local pre
    local post

    # Consume function_namespace() listener function once injection is complete
    local remove="remove_element_from_array \${function_namespace} BASH_ANNOTATIONS_FUNCTION_ARRAY"
    # Pre-invocation injection condition
    local listener="invoke_function_annotation_pre \$inject_annotated_function"
    # File @inject interface was invoked to allow for "introspecting" the correct script
    local source_file="$(realpath "${BASH_SOURCE[1]}")"
    # Function @inject has annotated
    local annotated_function="$(get_annotated_function "${source_file}")"

    if [[ -n "${annotated_function}" ]]; then
        local function_body 
        # Retrieve body of function @inject has annotated
        get_annotated_function_body "function_body" "${source_file}"

        if [[ -n "${function_body}" ]]; then
            if [[ "${location}" == "PRE" ]]; then
                pre="${function_body}"            
            elif [[ "${location}" == "POST" ]]; then
                post="${function_body}"
            elif [[ "${location}" == "PREPOST" ]]; then
                pre="${function_body}"            
                post="${function_body}"
            fi

            { source /dev/fd/999 ; } 999<<-DECLARE_INJECT_ANNOTATION_FUNCTION
            @${annotated_function}() {
                local function_namespace="\${FUNCNAME[0]}_\${BASH_LINENO[0]}"
                local source_file="\$(realpath "\${BASH_SOURCE[1]}")"
                local inject_annotated_function="\$(get_annotated_function "\${source_file}")"

                if [[ -n "\${inject_annotated_function}" ]]; then

                    { builtin source /dev/fd/999 ; } 999<<-DECLARE_INJECT_ANNOTATION_FUNCTION_NAMESPACE
                        \${function_namespace}() {
                            if ${listener}; then
                                inject_annotated_function_body="\\\$(declare -f \$inject_annotated_function)"
                                inject_annotated_function_body="\\\${inject_annotated_function_body#*{}"
                                inject_annotated_function_body="\\\${inject_annotated_function_body%\}}"

                                { builtin source /dev/fd/999 ; } 999<<-DECLARE_INJECTED_FUNCTION
                                \${inject_annotated_function}() {
                                    ${pre}
                                    \\\${inject_annotated_function_body}
                                    ${post}
                                }
DECLARE_INJECTED_FUNCTION
                            ${remove}
                            fi
                        }
DECLARE_INJECT_ANNOTATION_FUNCTION_NAMESPACE
                        BASH_ANNOTATIONS_FUNCTION_ARRAY+=("\${function_namespace}")
                else
                    return 1
                fi
            }
DECLARE_INJECT_ANNOTATION_FUNCTION
        fi
    fi
}


# Define valid location arguments for @inject
injection_location() {
    local location="${1}"

    case "${location}" in
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