#!/bin/bash

# source bash-annotations.sh
# import interfaces/interface_test.sh util/utility.sh interfaces/inject.sh annotations/ignore.sh annotations/debug.sh

source ./util/utility.sh


trap_controller() {
    if invoke_variable_annotation_post "string"; then
        echo "matched"
    fi
}

#set -o functrace
set -o history
trap 'trap_controller' DEBUG


@var() {
    local source_file="$(realpath "${BASH_SOURCE[1]}")"
    local annotated_variable="$(get_annotated_variable "${source_file}")"
    echo "${annotated_variable}"
}

invoke_variable_annotation_pre() {
    local target_variable="${1}" 

    if [[ "${BASH_COMMAND}" == *"\$${target_variable}"* ]] || \
    [[ "${BASH_COMMAND}" == *"\${${target_variable}}"* ]] || \
    [[ "${BASH_COMMAND}" == *"\${${target_variable}[@]}"* ]] || \
    [[ "${BASH_COMMAND}" == *"\${${target_variable}[*]}"* ]]; then
        return 0
    else
        return 1
    fi
}


invoke_variable_annotation_post() {
    local target_variable="${1}"
    local parse_history="$(builtin history 2 | head -1 | sed 's/^ *[0-9]* *//')"

    if [[ "${parse_history}" == *"\$${target_variable}"* ]] || \
    [[ "${parse_history}" == *"\${${target_variable}}"* ]] || \
    [[ "${parse_history}" == *"\${${target_variable}[@]}"* ]] || \
    [[ "${parse_history}" == *"\${${target_variable}[*]}"* ]]; then
        return 0
    else
        return 1
    fi
}


array=("one" "two")
invoke_variable_annotation_post "${array[@]}" 

declare string=("one" "two")
echo "to be or not to be is ${string[*]}"
echo "hl"