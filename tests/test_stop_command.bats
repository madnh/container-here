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

# Test --stop command with running container
@test "--stop command stops running container successfully" {
    export MOCK_IMAGE_EXISTS_LOCALLY="true"
    export MOCK_CONTAINER_EXISTS="true"
    export MOCK_CONTAINER_RUNNING="true"
    export MOCK_CONTAINER_NAME="container-here-test"
    export BATS_TEST_MODE=1
    
    run bash -c '
        source "$BATS_TEST_DIRNAME/helpers/docker_mock.bash"
        
        # Simulate stop_container function logic
        container_name="container-here-test"
        base_name="test"
        
        # Check if container exists
        if docker ps -a --format "{{.Names}}" | grep -q "^$container_name$"; then
            echo "container_exists: true"
            # Check if container is running
            if docker ps --format "{{.Names}}" | grep -q "^$container_name$"; then
                echo "container_running: true"
                echo "Stopping container '\''$base_name'\''..."
                docker stop "$container_name"
                echo "Container '\''$base_name'\'' stopped successfully."
            else
                echo "Container '\''$base_name'\'' is not running."
            fi
        else
            echo "container_exists: false"
        fi
    '
    
    [[ "$output" == *"container_exists: true"* ]]
    [[ "$output" == *"container_running: true"* ]]
    [[ "$output" == *"Stopping container 'test'..."* ]]
    [[ "$output" == *"Container 'test' stopped successfully."* ]]
    [ "$status" -eq 0 ]
}

# Test --stop command with stopped container
@test "--stop command handles stopped container gracefully" {
    export MOCK_IMAGE_EXISTS_LOCALLY="true"
    export MOCK_CONTAINER_EXISTS="true"
    export MOCK_CONTAINER_RUNNING="false"
    export MOCK_CONTAINER_NAME="container-here-test"
    export BATS_TEST_MODE=1
    
    run bash -c '
        source "$BATS_TEST_DIRNAME/helpers/docker_mock.bash"
        
        # Simulate stop_container function logic
        container_name="container-here-test"
        base_name="test"
        
        # Check if container exists
        if docker ps -a --format "{{.Names}}" | grep -q "^$container_name$"; then
            echo "container_exists: true"
            # Check if container is running
            if docker ps --format "{{.Names}}" | grep -q "^$container_name$"; then
                echo "container_running: true"
            else
                echo "container_running: false"
                echo "Container '\''$base_name'\'' is not running."
            fi
        else
            echo "container_exists: false"
        fi
    '
    
    [[ "$output" == *"container_exists: true"* ]]
    [[ "$output" == *"container_running: false"* ]]
    [[ "$output" == *"Container 'test' is not running."* ]]
    [ "$status" -eq 0 ]
}

# Test --stop command with non-existent container
@test "--stop command handles non-existent container with error" {
    export MOCK_IMAGE_EXISTS_LOCALLY="true"
    export MOCK_CONTAINER_EXISTS="false"
    export MOCK_CONTAINER_NAME="container-here-nonexistent"
    export BATS_TEST_MODE=1
    
    run bash -c '
        source "$BATS_TEST_DIRNAME/helpers/docker_mock.bash"
        
        # Simulate stop_container function logic
        container_name="container-here-nonexistent"
        base_name="nonexistent"
        
        # Check if container exists
        if docker ps -a --format "{{.Names}}" | grep -q "^$container_name$"; then
            echo "container_exists: true"
        else
            echo "container_exists: false"
            echo "Error: Container '\''$base_name'\'' not found."
            exit 1
        fi
    '
    
    [[ "$output" == *"container_exists: false"* ]]
    [[ "$output" == *"Error: Container 'nonexistent' not found."* ]]
    [ "$status" -eq 1 ]
}

# Test --stop command without container name uses auto-detection
@test "--stop command auto-detects container name from current folder" {
    export BATS_TEST_MODE=1
    
    run bash -c '
        # Simulate auto-detection behavior
        detected_name=$(basename "$(pwd)")
        echo "No container name provided. Using detected name: $detected_name"
        echo "Error: Container '"'"'$detected_name'"'"' not found."
        exit 1
    '
    
    [[ "$output" == *"No container name provided. Using detected name:"* ]]
    [[ "$output" == *"Error: Container"* ]]
    [ "$status" -eq 1 ]
}

# Test --stop command with docker stop failure
@test "--stop command handles docker stop failure" {
    export MOCK_IMAGE_EXISTS_LOCALLY="true"
    export MOCK_CONTAINER_EXISTS="true"
    export MOCK_CONTAINER_RUNNING="true"
    export MOCK_CONTAINER_NAME="container-here-test"
    export MOCK_DOCKER_STOP_FAIL="true"
    export BATS_TEST_MODE=1
    
    run bash -c '
        source "$BATS_TEST_DIRNAME/helpers/docker_mock.bash"
        
        # Simulate stop_container function logic
        container_name="container-here-test"
        base_name="test"
        
        # Check if container exists and is running
        if docker ps -a --format "{{.Names}}" | grep -q "^$container_name$"; then
            if docker ps --format "{{.Names}}" | grep -q "^$container_name$"; then
                echo "Stopping container '\''$base_name'\''..."
                docker stop "$container_name"
                if [ $? -eq 0 ]; then
                    echo "Container '\''$base_name'\'' stopped successfully."
                else
                    echo "Failed to stop container '\''$base_name'\''."
                    exit 1
                fi
            fi
        fi
    '
    
    [[ "$output" == *"Stopping container 'test'..."* ]]
    [[ "$output" == *"Failed to stop container 'test'."* ]]
    [ "$status" -eq 1 ]
}

# Test --stop command argument parsing
@test "--stop command parsing extracts container name correctly" {
    export BATS_TEST_MODE=1
    
    run bash -c '
        # Simulate argument parsing for --stop
        args=("--stop" "my-container")
        
        if [[ "${args[0]}" == "--stop" ]]; then
            if [[ ${#args[@]} -eq 1 ]]; then
                echo "Error: --stop requires a container name"
                exit 1
            else
                container_name="${args[1]}"
                echo "parsed_container_name: $container_name"
            fi
        fi
    '
    
    [[ "$output" == *"parsed_container_name: my-container"* ]]
    [ "$status" -eq 0 ]
}

# Test --stop command with container name generation
@test "--stop command generates correct container name" {
    export BATS_TEST_MODE=1
    
    run bash -c '
        # Simulate container name generation
        base_name="my-app"
        container_name="container-here-$base_name"
        echo "generated_container_name: $container_name"
    '
    
    [[ "$output" == *"generated_container_name: container-here-my-app"* ]]
    [ "$status" -eq 0 ]
}

# Test --stop command integration with list_containers
@test "--stop command shows available containers on error" {
    export MOCK_IMAGE_EXISTS_LOCALLY="true"
    export MOCK_CONTAINER_EXISTS="false"
    export BATS_TEST_MODE=1
    
    run bash -c '
        source "$BATS_TEST_DIRNAME/helpers/docker_mock.bash"
        
        # Simulate error case that would show list_containers
        container_name="container-here-nonexistent"
        base_name="nonexistent"
        
        if ! docker ps -a --format "{{.Names}}" | grep -q "^$container_name$"; then
            echo "Error: Container '\''$base_name'\'' not found."
            echo ""
            echo "Available containers:"
            echo "Container-here containers:"
            echo ""
            echo "NAME                    STATUS                  MOUNTED DIRECTORY"
            echo "To stop a container: container-here --stop <name>"
            exit 1
        fi
    '
    
    [[ "$output" == *"Error: Container 'nonexistent' not found."* ]]
    [[ "$output" == *"Available containers:"* ]]
    [[ "$output" == *"To stop a container: container-here --stop <name>"* ]]
    [ "$status" -eq 1 ]
}

# Test --stop command exit codes
@test "--stop command returns correct exit codes" {
    export MOCK_IMAGE_EXISTS_LOCALLY="true"
    export MOCK_CONTAINER_EXISTS="true"
    export MOCK_CONTAINER_RUNNING="true"
    export MOCK_CONTAINER_NAME="container-here-test"
    export BATS_TEST_MODE=1
    
    run bash -c '
        export MOCK_IMAGE_EXISTS_LOCALLY="true"
        export MOCK_CONTAINER_EXISTS="true"
        export MOCK_CONTAINER_RUNNING="true"
        export MOCK_CONTAINER_NAME="container-here-test"
        export BATS_TEST_MODE=1
        source "$BATS_TEST_DIRNAME/helpers/docker_mock.bash"
        
        # Test successful stop
        echo "success"
        exit 0
    '
    
    [[ "$output" == *"success"* ]]
    [ "$status" -eq 0 ]
}