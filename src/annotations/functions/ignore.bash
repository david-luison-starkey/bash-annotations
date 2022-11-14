import interfaces/interface.bash 


@interface FUNCTION PRE
# Unsets and redeclares an annotated function prior to invocation.
# Will cause annotation to return 0 exist status and do nothing more.
# Could have unexpected effects if used in if statement (or for boolean logic).
# Unaffected by function being declared more than once within a script.
# 
# Parameters: None
ignore() {
    unset -f '${annotated_function}'
    eval '${annotated_function}() { :; }' 
}
