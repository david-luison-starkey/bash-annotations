#!/usr/bin/env bash

# shellcheck disable=SC1090
source "$(realpath "$(dirname "${0}")"/../src/bash-annotations.bash)"
import interfaces/inject.bash

# The following script demonstrates how to create a custom inject annotation.
# Of note is the ability to access annotation variables by the annotated function.
# 
# Positional parameters must be escaped once so that they may be accessed correctly when
# an argument is passed to an annotation when the annotation is called. When the argument as 
# a positional variable is expanded, it does so correctly except for the precense of a leading 
# backslash. 
# 
# This must be dealt with in the annotated function with parameter expansion as this is not 
# handled by the @inject interface function.
#
# Positional parameters for @inject are the only variables requiring manual handling; both @inject
# and @interface (should) handle different variable and command substitution expansion in all other cases.
 

@inject PRE
get() {
    local url="\${1}"
    local non_argument_variable="Hello world"
}

 
sanitise_annotation_variable() {
    echo "${1#*\\}"
}


@get "www.google.com"
annotation_target() {
    local var="$(sanitise_annotation_variable "${url}")"
    curl -I --request GET "${var}"
    echo "${non_argument_variable}"
}

annotation_target
declare -f annotation_target
