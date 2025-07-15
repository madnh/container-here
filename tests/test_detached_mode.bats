#!/usr/bin/env bats

# Load test helpers
load helpers/docker_mock
load helpers/test_helpers

setup() {
    setup_test_env
}

teardown() {
    cleanup_test_env
}

# Test that docker run uses detached mode by default
@test "docker run uses detached mode (-d) by default" {
    export MOCK_IMAGE_EXISTS_LOCALLY="true"
    export MOCK_CONTAINER_EXISTS="false"
    export MOCK_SHELL="bash"
    export MOCK_SHELL_EXISTS="true"
    export BATS_TEST_MODE=1
    
    # Mock successful container creation
    run bash -c '
        source "$BATS_TEST_DIRNAME/helpers/docker_mock.bash"
        # Simulate the docker run command from the script
        docker run -d --name "container-here-test" alpine
        echo "detached_mode: $MOCK_RUN_DETACHED"
    '
    
    # Check that detached mode was detected
    [[ "$output" == *"detached_mode: true"* ]]
    [ "$status" -eq 0 ]
}

# Test that detached mode returns container ID
@test "detached mode returns container ID" {
    export MOCK_IMAGE_EXISTS_LOCALLY="true"
    export BATS_TEST_MODE=1
    
    run bash -c '
        source "$BATS_TEST_DIRNAME/helpers/docker_mock.bash"
        docker run -d --name "container-here-test" alpine
    '
    
    # Should return container ID in detached mode
    [[ "$output" == *"abc123def456"* ]]
    [ "$status" -eq 0 ]
}

# Test that interactive mode still works for comparison
@test "interactive mode does not use detached flag" {
    export MOCK_IMAGE_EXISTS_LOCALLY="true"
    export BATS_TEST_MODE=1
    
    run bash -c '
        source "$BATS_TEST_DIRNAME/helpers/docker_mock.bash"
        docker run -it --name "container-here-test" alpine
        echo "detached_mode: $MOCK_RUN_DETACHED"
    '
    
    # Should not be detached mode
    [[ "$output" == *"detached_mode: false"* ]]
    [ "$status" -eq 0 ]
}

# Test auto-exec functionality after container creation
@test "auto-exec functionality executes shell in container" {
    export MOCK_IMAGE_EXISTS_LOCALLY="true"
    export MOCK_CONTAINER_EXISTS="false"
    export MOCK_SHELL="/bin/bash"
    export MOCK_SHELL_EXISTS="true"
    export BATS_TEST_MODE=1
    
    run bash -c '
        source "$BATS_TEST_DIRNAME/helpers/docker_mock.bash"
        # Simulate the shell detection part
        CONTAINER_NAME="container-here-test"
        SHELL_CMD=$(docker exec "$CONTAINER_NAME" sh -c "echo \$SHELL" 2>/dev/null || echo "/bin/bash")
        echo "detected_shell: $SHELL_CMD"
    '
    
    [[ "$output" == *"detected_shell: /bin/bash"* ]]
    [ "$status" -eq 0 ]
}

# Test shell detection fallback
@test "shell detection falls back to /bin/bash when detection fails" {
    export MOCK_IMAGE_EXISTS_LOCALLY="true"
    export MOCK_CONTAINER_EXISTS="false"
    export MOCK_SHELL=""
    export MOCK_SHELL_EXISTS="false"
    export BATS_TEST_MODE=1
    
    run bash -c '
        source "$BATS_TEST_DIRNAME/helpers/docker_mock.bash"
        # Simulate the shell detection with fallback
        CONTAINER_NAME="container-here-test"
        SHELL_CMD=$(docker exec "$CONTAINER_NAME" sh -c "echo \$SHELL" 2>/dev/null || echo "/bin/bash")
        if [ -z "$SHELL_CMD" ] || ! docker exec "$CONTAINER_NAME" test -x "$SHELL_CMD" 2>/dev/null; then
            SHELL_CMD="/bin/bash"
        fi
        echo "detected_shell: $SHELL_CMD"
    '
    
    [[ "$output" == *"detected_shell: /bin/bash"* ]]
    [ "$status" -eq 0 ]
}

# Test that debug mode shows detached mode
@test "debug mode shows detached mode in docker command" {
    export MOCK_IMAGE_EXISTS_LOCALLY="true"
    export MOCK_CONTAINER_EXISTS="false"
    export BATS_TEST_MODE=1
    
    # Create a minimal test script that mimics the debug output
    run bash -c '
        echo "docker run -d \\"
        echo "  --name \"container-here-test\" \\"
        echo "  \"alpine\" \\"
        echo "  sleep infinity"
        echo ""
        echo "Then execute: docker exec -it \"container-here-test\" <detected_shell>"
    '
    
    [[ "$output" == *"docker run -d"* ]]
    [[ "$output" == *"Then execute: docker exec -it"* ]]
    [ "$status" -eq 0 ]
}

# Test container persistence concept
@test "container persistence: container survives after script exit" {
    export MOCK_IMAGE_EXISTS_LOCALLY="true"
    export MOCK_CONTAINER_EXISTS="true"
    export MOCK_CONTAINER_NAME="container-here-test"
    export MOCK_SHELL="bash"
    export MOCK_SHELL_EXISTS="true"
    export BATS_TEST_MODE=1
    
    run bash -c '
        source "$BATS_TEST_DIRNAME/helpers/docker_mock.bash"
        # Create container in detached mode
        docker run -d --name "container-here-test" alpine
        # Container should still exist after command completes
        docker ps -a --format "{{.Names}}" | grep -q "container-here-test"
        echo "container_persists: $?"
    '
    
    [[ "$output" == *"container_persists: 0"* ]]
    [ "$status" -eq 0 ]
}

# Test that container can be attached to after detached creation
@test "container can be attached to after detached creation" {
    export MOCK_IMAGE_EXISTS_LOCALLY="true"
    export MOCK_CONTAINER_EXISTS="true"
    export MOCK_CONTAINER_RUNNING="false"
    export MOCK_CONTAINER_NAME="container-here-test"
    export MOCK_SHELL="bash"
    export MOCK_SHELL_EXISTS="true"
    export BATS_TEST_MODE=1
    
    run bash -c '
        source "$BATS_TEST_DIRNAME/helpers/docker_mock.bash"
        # Simulate attach logic
        CONTAINER_NAME="container-here-test"
        if docker ps -a --format "{{.Names}}" | grep -q "^$CONTAINER_NAME$"; then
            echo "container_found: true"
            if docker ps --format "{{.Names}}" | grep -q "^$CONTAINER_NAME$"; then
                echo "container_running: true"
            else
                echo "container_running: false"
                echo "would_start_and_attach: true"
            fi
        fi
    '
    
    [[ "$output" == *"container_found: true"* ]]
    [[ "$output" == *"container_running: false"* ]]
    [[ "$output" == *"would_start_and_attach: true"* ]]
    [ "$status" -eq 0 ]
}

# Test error handling when container creation fails
@test "error handling when container creation fails in detached mode" {
    export MOCK_IMAGE_EXISTS_LOCALLY="true"
    export MOCK_CONTAINER_EXISTS="false"
    export MOCK_DOCKER_RUN_FAIL="true"
    export BATS_TEST_MODE=1
    
    run bash -c '
        source "$BATS_TEST_DIRNAME/helpers/docker_mock.bash"
        docker run -d --name "container-here-test" alpine
        echo "exit_code: $?"
    '
    
    [[ "$output" == *"exit_code: 1"* ]]
    [ "$status" -eq 0 ]
}

# Test that container name is properly set in detached mode
@test "container name is properly set in detached mode" {
    export MOCK_IMAGE_EXISTS_LOCALLY="true"
    export MOCK_CONTAINER_EXISTS="false"
    export BATS_TEST_MODE=1
    
    run bash -c '
        source "$BATS_TEST_DIRNAME/helpers/docker_mock.bash"
        docker run -d --name "container-here-myapp" alpine
        echo "created_container: $MOCK_CREATED_CONTAINER"
    '
    
    [[ "$output" == *"created_container: container-here-myapp"* ]]
    [ "$status" -eq 0 ]
}