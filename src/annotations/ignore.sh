import interfaces/interface.sh 


@interface "function" "pre"
ignore() {
    unset -f '${annotated_function}'
    eval '${annotated_function}() { :; }' 
}
