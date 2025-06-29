#!/bin/bash

# Common test utilities

# Load the script under test
load_script() {
    # Source the container-here script but prevent it from running
    export BATS_TEST_MODE=1
    source "$BATS_TEST_DIRNAME/../container-here"
}

# Mock date command for consistent timestamps
date() {
    if [[ "$1" == "+%s" ]]; then
        echo "1234567890"
    else
        command date "$@"
    fi
}

# Mock basename command
basename() {
    if [[ "$1" == "$(pwd)" ]] || [[ "$1" == "/current/test/dir" ]]; then
        echo "test-folder"
    else
        command basename "$@"
    fi
}

# Mock pwd command
pwd() {
    echo "/current/test/dir"
}

# Setup test environment
setup_test_env() {
    export PATH="$BATS_TEST_DIRNAME/helpers:$PATH"
    reset_docker_mocks
}

# Cleanup test environment
cleanup_test_env() {
    reset_docker_mocks
    unset BATS_TEST_MODE
}

# Export functions
export -f date
export -f basename
export -f pwd
export -f load_script
export -f setup_test_env
export -f cleanup_test_env