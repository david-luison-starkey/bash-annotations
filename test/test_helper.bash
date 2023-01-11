#!/usr/bin/env bash

common_setup() {
    load 'test_helper/bats-support/load'
    load 'test_helper/bats-assert/load'
    PROJECT_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." >/dev/null 2>&1 && pwd)"
    # make executables in src/ visible to PATH
    PATH="$PROJECT_ROOT/src:$PATH"
}
