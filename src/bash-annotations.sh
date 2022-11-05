#!/bin/bash

declare -gax BASH_ANNOTATIONS_IMPORT_ARRAY
declare -gax BASH_ANNOTATIONS_FUNCTION_ARRAY
declare -gx BASH_ANNOTATIONS_PROJECT_BASE_DIRECTORY="$(dirname "$(realpath "${BASH_SOURCE[0]}")")/"


# Basic import function intended to be used internally by project
function import() {
    local to_source=("${@}")

    _is_imported() {
        local import_requested="${1}"
        for imported in "${BASH_ANNOTATIONS_IMPORT_ARRAY[@]}"; do
            [[ "${import_requested}" == "${imported}" ]] && return 0
        done
        return 1
    }

    for script in "${to_source[@]}"; do 
        if ! _is_imported "${script}" && \
        [[ -f "${BASH_ANNOTATIONS_PROJECT_BASE_DIRECTORY}${script}" ]]; then 
            BASH_ANNOTATIONS_IMPORT_ARRAY+=("${script}")
            builtin source "${BASH_ANNOTATIONS_PROJECT_BASE_DIRECTORY}${script}" 
        else
            continue
        fi
    done
}


bash_annotations_trap_controller() {
    for func in "${BASH_ANNOTATIONS_FUNCTION_ARRAY[@]}"; do
        if type -t "${func}" 1> /dev/null; then
            ${func}
        fi
    done
}


set_bash_annotations_trap() {
    builtin trap "bash_annotations_trap_controller" DEBUG
}


@setup() {
    # functrace has to be turned off to avoid superfluous function calls from
    # trap_controller()
    set -o history
    set_bash_annotations_trap
}

@setup
