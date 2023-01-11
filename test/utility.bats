#!/usr/bin/env bats

setup() {
    load "test_helper"
    common_setup
    load "${BATS_TEST_DIRNAME}/../src/util/utility.bash"
}

@test "remove_element_from_array removes requested value" {
    local numbers=(one two three)
    remove_element_from_array "two" numbers
    run echo "${numbers[*]}"
    assert_output "one three"
}

@test "remove_element_from_array removes duplicate requested values" {
    local numbers=(one two three three three)
    remove_element_from_array "three" numbers
    run echo "${numbers[*]}"
    assert_output "one two"
}

@test "is_element_in_array detects present value" {
    local numbers=(one two three)
    run is_element_in_array "two" "${numbers[@]}"
    assert_success
    run is_element_in_array "four" "${numbers[@]}"
    assert_failure
}

@test "trim performs left and right trim" {
    local variable="     spaces         "
    run trim "${variable}"
    assert_output "spaces"
}
