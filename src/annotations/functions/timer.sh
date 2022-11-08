import interfaces/interface.sh


@interface FUNCTION PREPOST
# https://unix.stackexchange.com/questions/314365/get-elapsed-time-in-bash 
timer() {
    declare -gx bash_annotations_timer_start
    declare -gx bash_annotations_timer_end

    if invoke_function_annotation_pre "${annotated_function}" && \
    [[ -z "${bash_annotations_timer_start}" ]]; then
        bash_annotations_timer_start=$(date -u +%s.%N)
    elif invoke_function_annotation_post "${annotated_function}" && \
    [[ -n "${bash_annotations_timer_start}" ]]; then
        bash_annotations_timer_end=$(date -u +%s.%N)
        printf "%s() runtime: " "${annotated_function}"
        printf "%0.4f seconds\n" "$(bc -q <<< "scale=4; $bash_annotations_timer_end - $bash_annotations_timer_start")"
        unset timer_start
        unset timer_end
    fi
}