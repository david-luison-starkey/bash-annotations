import interfaces/inject.sh


@inject "prepost"
debug() {
    if ! [[ -o xtrace ]]; then
        set -x
    else
        set +x
    fi
}
