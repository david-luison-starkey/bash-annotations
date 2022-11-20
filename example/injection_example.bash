#!/usr/bin/env bash

# shellcheck disable=SC1090
source "$(realpath "$(dirname "${0}")"/../src/bash-annotations.bash)"
import interfaces/inject.bash

# The following script demonstrates how to create a custom inject annotation.
# Of note is the ability to access annotation variables by the annotated function.
# 
# Positional parameters and special variables must exist on separate lines to all
# other variables and command substitutions (as the $ sumbol is escaped differently). 
# 
# Positional parameters and special variables may exist on the same lines as each other.
#
# bash-annotations special variables may also be accessed by annotated functions.
# To do so, assign the special variable to a variable within the annotation itself.
# This can then be accessed within the function that is annotated. 


@inject PRE
get() {
    local url="${1}"; local target_function="${inject_annotated_function}";
    local non_argument_variable="Hello world"
}

@get "www.google.com"
annotation_target() {
    # Positional argument passed to the annotation and accessible by the annotated function
    curl -I --request GET "${url}"
    # Access special variable (In this case, this function's name)
    echo "${target_function}"
    # Regular variable declared inside the annotation initially
    echo "${non_argument_variable}"
}

annotation_target

declare -f annotation_target
