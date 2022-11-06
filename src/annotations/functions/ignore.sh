import interfaces/interface.sh 


@interface FUNCTION PRE
# Unsets and redeclares an annotated function prior to invocation.
# Unimpeded by function being declared more than once within a script.
ignore() {
    unset -f '${annotated_function}'
    eval '${annotated_function}() { :; }' 
}
