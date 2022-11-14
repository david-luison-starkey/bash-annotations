import interfaces/inject.sh


@inject PREPOST
# Basic foundation for function specific debug functionality.
# 
# Parameters: None
debug() {
    if ! [[ -o xtrace ]]; then
        set -x
    else
        set +x
    fi
}
