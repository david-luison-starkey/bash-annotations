import interfaces/interface.sh 
import util/types.sh


@interface VARIABLE PRE
# Enforces strong typing at runtime for an annotated type.
# Can be used on variables (and commands passed as positional
# parameters - most relevant for functions passed as arguments).
element_type() {
    local type_assertion="${1}"
    if ! check_type "${annotated_variable}" \
    "${type_assertion}"; then
        exit 1
    fi
}
