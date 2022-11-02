#!/bin/bash

declare -gax BASH_ANNOTATIONS_IMPORT_ARRAY
declare -gax BASH_ANNOTATIONS_FUNCTION_ARRAY


function import() {
    local to_source=("${@}")

    _is_imported() {
        local import_requested="${1}"; shift;
        for imported in "${BASH_ANNOTATIONS_IMPORT_ARRAY[@]}"; do
            [[ "${import_requested}" == "${imported}" ]] && return 0
        done
        return 1
    }

    for script in "${to_source[@]}"; do 
        if ! _is_imported "${script}" && \
        [[ -f "${script}" ]]; then 
            builtin source "${script}" 
            BASH_ANNOTATIONS_IMPORT_ARRAY+=("${script}")
        else
            continue
        fi
    done
}


trap_controller() {
    for func in "${BASH_ANNOTATIONS_FUNCTION_ARRAY[@]}"; do
        if type -t "${func}" 1> /dev/null; then
            ${func}
        fi
    done
}


set_bash_annotations_trap() {
    builtin trap "trap_controller" DEBUG
}


@setup() {
    # functrace has to be turned off to avoid superfluous function calls from
    # trap_controller()
    set +o functrace
    set -o history
    set_bash_annotations_trap
}

@setup