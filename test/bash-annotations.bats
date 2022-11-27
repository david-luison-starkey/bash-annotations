#!/usr/bin/env bats


setup() {
    load "test_helper"
    common_setup
    load "${BATS_TEST_DIRNAME}/../src/bash-annotations.bash"
}

@test "bash_annotations_setup sets options and DEBUG trap" {
    run bash_annotations_setup 
    eval '[ -o history ]'
    assert_success
    eval '[ -o functrace ]'
    assert_success
    run echo "$(trap -p DEBUG)"
    assert_output "trap -- 'bash_annotations_trap_controller' DEBUG"
}

@test "import does not source duplicates" {
    import util/utility.bash
    import util/utility.bash
    assert_equal "${#BASH_ANNOTATIONS_IMPORT_ARRAY[@]}" 1
}
