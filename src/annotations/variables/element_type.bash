import interfaces/interface.bash 
import util/types.bash


@interface VARIABLE PRE
# Enforces strong typing at runtime for an annotated type for positional parameters assigned to variables.
# 
# At present, only works when a type is passed as an argument (e.g. declare -i integer=22; function() "integer",
# not function() "22")
# 
# Both variable and command types (e.g. "FUNCTION") can be enforced. 
# Annotate variable declaration and/or initialisation. This annotation evaluates 
# lazily, and will perform type checking when the annotated variable is called.
#
# Parameter 1: Variable or command type
#
# Valid values:
# 
# Variables: STRING, ARRAY, ASSOCIATIVE, INTEGER, NAMEREF
#
# Commands: ALIAS, KEYWORD, FUNCTION, BUILTIN, FILE
#
# Example:
# 
# 
# declare -a example_array 
# 
# example_function() {
# 
# @element_type ARRAY 
# local variable="${1}"
# 
# }
# 
# example_function "${example_array[@]}"
#
# Notes: 
# 
# ASSOCIATE=Associative array
# 
# If the type a name refereced (-n) variable is to be enforced, then annotate with
# the actual variable type. 
# 
# If the intended type is indeed -n, specify NAMEREF. 
element_type() {
    local type_assertion="${1}"
    local value="${annotated_variable}"
    if ! check_type "${!value}" "${type_assertion}"; then
        exit 1
    fi
}
