#!/usr/bin/env bash

declare -gax BASH_ANNOTATIONS_IMPORT_ARRAY
declare -gax BASH_ANNOTATIONS_FUNCTION_ARRAY
# Ensure variable is always set to project src/ directory: https://stackoverflow.com/a/17744637
declare -gx BASH_ANNOTATIONS_PROJECT_BASE_DIRECTORY="$(cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)/"

# Private function to check if item is in array.
# Avoids external dependency on util/utility.sh is_element_in_array()
_is_imported() {
    local import_requested="${1}"
    for imported in "${BASH_ANNOTATIONS_IMPORT_ARRAY[@]}"; do
        [[ "${import_requested}" == "${imported}" ]] && return 0
    done
    return 1
}

# Basic import function intended to be used internally by project
import() {
    local to_source=("${@}")

    # Source a script once and once only
    for script in "${to_source[@]}"; do
        if ! _is_imported "${script}" &&
            [[ -f "${BASH_ANNOTATIONS_PROJECT_BASE_DIRECTORY}${script}" ]]; then
            BASH_ANNOTATIONS_IMPORT_ARRAY+=("${script}")
            builtin source "${BASH_ANNOTATIONS_PROJECT_BASE_DIRECTORY}${script}"
        else
            continue
        fi
    done
}

# Loops through global array that stores functions created by annotations
bash_annotations_trap_controller() {
    for func in "${BASH_ANNOTATIONS_FUNCTION_ARRAY[@]}"; do
        # Basic sanity check to ensure function exists
        if type -t "${func}" 1>/dev/null; then
            ${func}
        fi
    done
}

set_bash_annotations_trap() {
    builtin trap "bash_annotations_trap_controller" DEBUG
}

bash_annotations_setup() {
    set -o functrace
    set -o history
    set_bash_annotations_trap
}

bash_annotations_setup
