#!/usr/bin/env bats


setup() {
    load 'test_helper'
    _common_setup
    source "${BATS_TEST_DIRNAME}/../src/bash-annotations.sh"
    source "${BATS_TEST_DIRNAME}/../src/interfaces/interface.sh"
    source "${BATS_TEST_DIRNAME}/../src/reflection.sh"
    source "${BATS_TEST_DIRNAME}/../src/util/utility.sh"

    run source "${BATS_TEST_DIRNAME}/../src/bash-annotations.sh"
}

@test 'bash-annotations.sh is runnable' {
    skip
    bash-annotations.sh
}

@test '@ignore fails when there is no function to annotate' {
    skip
    run bash_annotations_setup
    eval '[ -o history ]'
    [ "$status" -eq 0 ]
    # On failure, the expected and actual values are displayed.
    # -- values do not equal --
    # expected : want
    # actual   : have
    # --
}


@test 'describe test for assert()' {
    skip
    history -s "target_function() {"
    invoke_function_annotation_post "target_function"
    assert_success
}



@test "Confirm correct bash_annotations_setup()" {
    eval '[ -o history ]'
    assert_success
    eval '[ -o functrace ]'
    assert_success
    run echo "$(trap -p DEBUG)"
    assert_output "trap -- 'bash_annotations_trap_controller' DEBUG"
}


