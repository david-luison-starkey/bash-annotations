#!/usr/bin/env bats


setup() {
    load 'test_helper'
    _common_setup
    source "${BATS_TEST_DIRNAME}/../src/bash-annotations.bash"
}

@test "bash-annotations.bash is executable" {
    bash-annotations.bash
}

@test "Confirm correct bash_annotations_setup()" {
    run source "${BATS_TEST_DIRNAME}/../src/bash-annotations.bash"
    eval '[ -o history ]'
    assert_success
    eval '[ -o functrace ]'
    assert_success
    run echo "$(trap -p DEBUG)"
    assert_output "trap -- 'bash_annotations_trap_controller' DEBUG"
}


