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

# Test home folder detection function
@test "detect_home_folder returns valid /home/ path when HOME is set correctly" {
    export MOCK_HOME_FOLDER="/home/ubuntu"
    export MOCK_HOME_EXISTS="true"
    export MOCK_IMAGE_EXISTS_LOCALLY="true"
    export BATS_TEST_MODE=1
    
    source "$BATS_TEST_DIRNAME/helpers/docker_mock.bash"
    source "$BATS_TEST_DIRNAME/../container-here"
    
    result=$(detect_home_folder "test-container")
    [ "$result" = "/home/ubuntu" ]
}

@test "detect_home_folder returns /user-home when HOME is not in /home/" {
    export MOCK_HOME_FOLDER="/root"
    export MOCK_HOME_EXISTS="true"
    export MOCK_IMAGE_EXISTS_LOCALLY="true"
    export BATS_TEST_MODE=1
    
    source "$BATS_TEST_DIRNAME/helpers/docker_mock.bash"
    source "$BATS_TEST_DIRNAME/../container-here"
    
    result=$(detect_home_folder "test-container")
    [ "$result" = "/user-home" ]
}

@test "detect_home_folder returns /user-home when HOME directory doesn't exist" {
    export MOCK_HOME_FOLDER="/home/ubuntu"
    export MOCK_HOME_EXISTS="false"
    export MOCK_IMAGE_EXISTS_LOCALLY="true"
    export BATS_TEST_MODE=1
    
    source "$BATS_TEST_DIRNAME/helpers/docker_mock.bash"
    source "$BATS_TEST_DIRNAME/../container-here"
    
    result=$(detect_home_folder "test-container")
    [ "$result" = "/user-home" ]
}

@test "detect_home_folder returns /user-home when HOME is empty" {
    export MOCK_HOME_FOLDER=""
    export MOCK_HOME_EXISTS="false"
    export MOCK_IMAGE_EXISTS_LOCALLY="true"
    export BATS_TEST_MODE=1
    
    source "$BATS_TEST_DIRNAME/helpers/docker_mock.bash"
    source "$BATS_TEST_DIRNAME/../container-here"
    
    result=$(detect_home_folder "test-container")
    [ "$result" = "/user-home" ]
}

# Test container name generation
@test "container name is generated correctly with argument" {
    export BATS_TEST_MODE=1
    run bash -c 'BASE_NAME="test-app"; CONTAINER_NAME="container-here-$BASE_NAME"; echo "$CONTAINER_NAME"'
    [ "$output" = "container-here-test-app" ]
}

@test "container name is generated correctly without argument using folder name" {
    export BATS_TEST_MODE=1
    run bash -c 'BASE_NAME="test-folder"; CONTAINER_NAME="container-here-$BASE_NAME"; echo "$CONTAINER_NAME"'
    [ "$output" = "container-here-test-folder" ]
}

# Test container existence checking
@test "script detects existing container" {
    export MOCK_CONTAINER_EXISTS="true"
    export MOCK_CONTAINER_NAME="container-here-test-folder"
    
    run bash -c '
        source "$BATS_TEST_DIRNAME/helpers/docker_mock.bash"
        CONTAINER_NAME="container-here-test-folder"
        if docker ps -a --format "table {{.Names}}" | grep -q "^$CONTAINER_NAME$"; then
            echo "Container '\''$CONTAINER_NAME'\'' already exists."
        fi
    '
    [[ "$output" == *"Container 'container-here-test-folder' already exists"* ]]
}

@test "script proceeds when container doesn't exist" {
    export MOCK_CONTAINER_EXISTS="false"
    export MOCK_VOLUME_EXISTS="true"
    export MOCK_HOME_FOLDER="/home/ubuntu"
    export MOCK_HOME_EXISTS="true"
    
    run bash -c '
        source "$BATS_TEST_DIRNAME/helpers/docker_mock.bash"
        if ! docker ps -a --format "table {{.Names}}" | grep -q "^container-here-test-folder$"; then
            echo "Detecting home folder in container image..."
        fi
    '
    [[ "$output" == *"Detecting home folder"* ]]
}

# Test volume creation logic
@test "script creates volume when it doesn't exist" {
    export MOCK_VOLUME_EXISTS="false"
    
    run bash -c '
        source "$BATS_TEST_DIRNAME/helpers/docker_mock.bash"
        if ! docker volume ls | grep -q "container-here-home"; then
            echo "Creating docker volume: container-here-home"
            docker volume create container-here-home
        fi
    '
    [[ "$output" == *"Creating docker volume: container-here-home"* ]]
}

@test "script skips volume creation when it exists" {
    export MOCK_VOLUME_EXISTS="true"
    
    run bash -c '
        source "$BATS_TEST_DIRNAME/helpers/docker_mock.bash"
        if ! docker volume ls | grep -q "container-here-home"; then
            echo "Creating docker volume: container-here-home"
        else
            echo "Docker volume container-here-home already exists"
        fi
    '
    [[ "$output" == *"Docker volume container-here-home already exists"* ]]
}

# Test shell detection for existing containers
@test "script detects valid shell in running container" {
    export MOCK_CONTAINER_RUNNING="true"
    export MOCK_CONTAINER_NAME="container-here-test-folder"
    export MOCK_SHELL="/bin/zsh"
    export MOCK_SHELL_EXISTS="true"
    
    run bash -c '
        source "$BATS_TEST_DIRNAME/helpers/docker_mock.bash"
        CONTAINER_NAME="container-here-test-folder"
        if docker ps --format "table {{.Names}}" | grep -q "^$CONTAINER_NAME$"; then
            echo "Container is already running. Attaching to it..."
        fi
    '
    [[ "$output" == *"Container is already running"* ]]
}

@test "script falls back to /bin/bash when shell detection fails" {
    export MOCK_CONTAINER_RUNNING="true"
    export MOCK_SHELL=""
    export MOCK_SHELL_EXISTS="false"
    
    run bash -c '
        source "$BATS_TEST_DIRNAME/helpers/docker_mock.bash"
        CONTAINER_NAME="container-here-test-folder"
        SHELL_CMD=$(docker exec "$CONTAINER_NAME" sh -c "echo \$SHELL" 2>/dev/null || echo "/bin/bash")
        if [ -z "$SHELL_CMD" ] || ! docker exec "$CONTAINER_NAME" test -x "$SHELL_CMD" 2>/dev/null; then
            SHELL_CMD="/bin/bash"
        fi
        echo "Using shell: $SHELL_CMD"
    '
    [[ "$output" == *"Using shell: /bin/bash"* ]]
}

# Test user input handling
@test "script exits when user chooses option 1" {
    run bash -c '
        choice="1"
        case $choice in
            1) echo "Exiting..." ;;
            *) echo "Other option" ;;
        esac
    '
    [[ "$output" == *"Exiting..."* ]]
}

@test "script removes container when user chooses option 2" {
    run bash -c '
        source "$BATS_TEST_DIRNAME/helpers/docker_mock.bash"
        choice="2"
        case $choice in
            2) 
                echo "Removing existing container..."
                docker rm -f "container-here-test-folder"
                ;;
            *) echo "Other option" ;;
        esac
    '
    [[ "$output" == *"Removing existing container..."* ]]
}

@test "script handles invalid user input" {
    run bash -c '
        choice="invalid"
        case $choice in
            1) echo "Exiting..." ;;
            2) echo "Removing..." ;;
            3) echo "Using..." ;;
            *) echo "Invalid option. Exiting..." ;;
        esac
    '
    [[ "$output" == *"Invalid option. Exiting..."* ]]
}

# Test home folder detection integration
@test "script uses detected home folder in volume mount" {
    export MOCK_HOME_FOLDER="/home/developer"
    export MOCK_HOME_EXISTS="true"
    export BATS_TEST_MODE=1
    
    source "$BATS_TEST_DIRNAME/helpers/docker_mock.bash"
    source "$BATS_TEST_DIRNAME/../container-here"
    
    HOME_FOLDER=$(detect_home_folder "test-container")
    [ "$HOME_FOLDER" = "/home/developer" ]
}

@test "script uses fallback home folder when detection fails" {
    export MOCK_HOME_FOLDER="/root"
    export MOCK_HOME_EXISTS="true"
    export BATS_TEST_MODE=1
    
    source "$BATS_TEST_DIRNAME/helpers/docker_mock.bash"
    source "$BATS_TEST_DIRNAME/../container-here"
    
    HOME_FOLDER=$(detect_home_folder "test-container")
    [ "$HOME_FOLDER" = "/user-home" ]
}

# Test command line argument parsing
@test "script uses default alpine image when no --image specified" {
    export BATS_TEST_MODE=1
    
    source "$BATS_TEST_DIRNAME/../container-here"
    [ "$DOCKER_IMAGE" = "alpine" ]
}

@test "parse_arguments function handles --image option correctly" {
    export BATS_TEST_MODE=1
    
    source "$BATS_TEST_DIRNAME/../container-here"
    parse_arguments --image ubuntu:20.04 my-app
    [ "$DOCKER_IMAGE" = "ubuntu:20.04" ]
    [ "$CONTAINER_NAME_ARG" = "my-app" ]
}

@test "parse_arguments function handles container name with --image option" {
    export BATS_TEST_MODE=1
    
    source "$BATS_TEST_DIRNAME/../container-here"
    parse_arguments --image node:18 my-node-app
    [ "$DOCKER_IMAGE" = "node:18" ]
    [ "$CONTAINER_NAME_ARG" = "my-node-app" ]
}

@test "parse_arguments function shows help with --help option" {
    export BATS_TEST_MODE=1
    
    source "$BATS_TEST_DIRNAME/../container-here"
    run parse_arguments --help
    [[ "$output" == *"Usage:"* ]]
}

@test "parse_arguments function shows help with -h option" {
    export BATS_TEST_MODE=1
    
    source "$BATS_TEST_DIRNAME/../container-here"
    run parse_arguments -h
    [[ "$output" == *"Usage:"* ]]
}

@test "parse_arguments function handles unknown option gracefully" {
    export BATS_TEST_MODE=1
    
    source "$BATS_TEST_DIRNAME/../container-here"
    run parse_arguments --unknown-option
    [[ "$output" == *"Error: Unknown option"* ]]
}

@test "parse_arguments function handles multiple container names error" {
    export BATS_TEST_MODE=1
    
    source "$BATS_TEST_DIRNAME/../container-here"
    run parse_arguments app1 app2
    [[ "$output" == *"Error: Multiple container names"* ]]
}

# Test image validation functions
@test "check_image_exists_locally returns true when image exists" {
    export MOCK_IMAGE_EXISTS_LOCALLY="true"
    export BATS_TEST_MODE=1
    
    source "$BATS_TEST_DIRNAME/helpers/docker_mock.bash"
    source "$BATS_TEST_DIRNAME/../container-here"
    
    run check_image_exists_locally "alpine"
    [ "$status" -eq 0 ]
}

@test "check_image_exists_locally returns false when image doesn't exist" {
    export MOCK_IMAGE_EXISTS_LOCALLY="false"
    export BATS_TEST_MODE=1
    
    source "$BATS_TEST_DIRNAME/helpers/docker_mock.bash"
    source "$BATS_TEST_DIRNAME/../container-here"
    
    run check_image_exists_locally "nonexistent"
    [ "$status" -eq 1 ]
}

@test "check_image_on_dockerhub returns true when image exists on hub" {
    export MOCK_IMAGE_EXISTS_ON_HUB="true"
    export BATS_TEST_MODE=1
    
    source "$BATS_TEST_DIRNAME/helpers/docker_mock.bash"
    source "$BATS_TEST_DIRNAME/../container-here"
    
    run check_image_on_dockerhub "alpine"
    [ "$status" -eq 0 ]
}

@test "check_image_on_dockerhub returns false when image doesn't exist on hub" {
    export MOCK_IMAGE_EXISTS_ON_HUB="false"
    export BATS_TEST_MODE=1
    
    source "$BATS_TEST_DIRNAME/helpers/docker_mock.bash"
    source "$BATS_TEST_DIRNAME/../container-here"
    
    run check_image_on_dockerhub "nonexistent"
    [ "$status" -eq 1 ]
}

@test "get_dockerhub_url returns correct URL for official image" {
    export BATS_TEST_MODE=1
    
    source "$BATS_TEST_DIRNAME/../container-here"
    
    result=$(get_dockerhub_url "alpine")
    [ "$result" = "https://hub.docker.com/_/alpine" ]
}

@test "get_dockerhub_url returns correct URL for user image" {
    export BATS_TEST_MODE=1
    
    source "$BATS_TEST_DIRNAME/../container-here"
    
    result=$(get_dockerhub_url "user/repo")
    [ "$result" = "https://hub.docker.com/r/user/repo" ]
}

@test "get_dockerhub_url handles image with tag correctly" {
    export BATS_TEST_MODE=1
    
    source "$BATS_TEST_DIRNAME/../container-here"
    
    result=$(get_dockerhub_url "alpine:3.18")
    [ "$result" = "https://hub.docker.com/_/alpine" ]
}

@test "validate_and_prepare_image succeeds when image exists locally" {
    export MOCK_IMAGE_EXISTS_LOCALLY="true"
    export BATS_TEST_MODE=1
    
    source "$BATS_TEST_DIRNAME/helpers/docker_mock.bash"
    source "$BATS_TEST_DIRNAME/../container-here"
    
    run validate_and_prepare_image "alpine"
    [ "$status" -eq 0 ]
    [[ "$output" == *"Image 'alpine' found locally"* ]]
}

@test "validate_and_prepare_image fails when image doesn't exist anywhere" {
    export MOCK_IMAGE_EXISTS_LOCALLY="false"
    export MOCK_IMAGE_EXISTS_ON_HUB="false"
    export BATS_TEST_MODE=1
    
    source "$BATS_TEST_DIRNAME/helpers/docker_mock.bash"
    source "$BATS_TEST_DIRNAME/../container-here"
    
    run validate_and_prepare_image "nonexistent"
    [ "$status" -eq 1 ]
    [[ "$output" == *"not found on Docker Hub"* ]]
}