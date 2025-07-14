#!/bin/bash

# Docker mock functions for testing

# Mock docker ps command
mock_docker_ps() {
    if [[ "$*" == *"-a"* ]] && [[ "$*" == *"--format"* ]]; then
        # All containers (including stopped)
        if [[ "$MOCK_CONTAINER_EXISTS" == "true" ]]; then
            echo "NAMES"
            echo "$MOCK_CONTAINER_NAME"
        else
            echo "NAMES"
        fi
    elif [[ "$*" == *"--format"* ]] && [[ "$*" != *"-a"* ]]; then
        # Running containers only
        if [[ "$MOCK_CONTAINER_RUNNING" == "true" ]]; then
            echo "NAMES"
            echo "$MOCK_CONTAINER_NAME"
        else
            echo "NAMES"
        fi
    fi
}

# Mock docker volume ls command
mock_docker_volume_ls() {
    if [[ "$MOCK_VOLUME_EXISTS" == "true" ]]; then
        echo "DRIVER    VOLUME NAME"
        echo "local     container-here-home"
    else
        echo "DRIVER    VOLUME NAME"
    fi
}

# Mock docker volume create command
mock_docker_volume_create() {
    echo "container-here-home"
}

# Mock docker exec command
mock_docker_exec() {
    local container_name="$1"
    shift
    
    if [[ "$*" == *"echo \$HOME"* ]]; then
        echo "$MOCK_HOME_FOLDER"
        return 0
    elif [[ "$*" == *"echo \$SHELL"* ]]; then
        echo "$MOCK_SHELL"
        return 0
    elif [[ "$*" == *"test -d"* ]]; then
        if [[ "$MOCK_HOME_EXISTS" == "true" ]]; then
            return 0
        else
            return 1
        fi
    elif [[ "$*" == *"test -x"* ]]; then
        if [[ "$MOCK_SHELL_EXISTS" == "true" ]]; then
            return 0
        else
            return 1
        fi
    fi
    
    return 0
}

# Mock docker run command
mock_docker_run() {
    if [[ "$*" == *"--name"* ]]; then
        # Extract container name from arguments
        local args=("$@")
        for i in "${!args[@]}"; do
            if [[ "${args[i]}" == "--name" ]]; then
                MOCK_CREATED_CONTAINER="${args[i+1]}"
                break
            fi
        done
    fi
    
    # Extract image name (last argument that doesn't start with -)
    local args=("$@")
    for ((i=${#args[@]}-1; i>=0; i--)); do
        if [[ "${args[i]}" != -* ]] && [[ "${args[i]}" != *":"* ]] && [[ "${args[i]}" != *"/"* ]] && [[ "${args[i]}" != "echo" ]] && [[ "${args[i]}" != "temp" ]]; then
            continue
        elif [[ "${args[i]}" != -* ]] && [[ "${args[i]}" != "echo" ]] && [[ "${args[i]}" != "temp" ]]; then
            MOCK_USED_IMAGE="${args[i]}"
            break
        fi
    done
    
    if [[ "$MOCK_DOCKER_RUN_FAIL" == "true" ]]; then
        return 1
    fi
    
    echo "Container created successfully"
    return 0
}

# Mock docker rm command
mock_docker_rm() {
    echo "Container removed"
    return 0
}

# Mock docker start command
mock_docker_start() {
    echo "Container started"
    return 0
}

# Mock docker image inspect command
mock_docker_image_inspect() {
    local image="$1"
    if [[ "$MOCK_IMAGE_EXISTS_LOCALLY" == "true" ]]; then
        echo "Image exists locally"
        return 0
    else
        return 1
    fi
}

# Mock docker pull command
mock_docker_pull() {
    local image="$1"
    if [[ "$MOCK_DOCKER_PULL_FAIL" == "true" ]]; then
        echo "Error pulling image"
        return 1
    else
        echo "Successfully pulled $image"
        return 0
    fi
}

# Mock docker network ls command
mock_docker_network_ls() {
    if [[ "$*" == *"--format"* ]]; then
        if [[ "$MOCK_NETWORK_EXISTS" == "true" ]]; then
            echo "$MOCK_NETWORK_NAME"
        fi
        # Always show default networks
        echo "bridge"
        echo "host"
        echo "none"
    else
        echo "NETWORK ID     NAME      DRIVER    SCOPE"
        echo "1234567890ab   bridge    bridge    local"
        echo "2345678901bc   host      host      local"
        echo "3456789012cd   none      null      local"
        if [[ "$MOCK_NETWORK_EXISTS" == "true" ]]; then
            echo "4567890123de   $MOCK_NETWORK_NAME   bridge    local"
        fi
    fi
}

# Mock curl command for Docker Hub API
curl() {
    if [[ "$*" == *"hub.docker.com"* ]]; then
        if [[ "$MOCK_IMAGE_EXISTS_ON_HUB" == "true" ]]; then
            echo "200"
        else
            echo "404"
        fi
    else
        command curl "$@"
    fi
}

# Main docker mock function
docker() {
    case "$1" in
        "ps")
            shift
            mock_docker_ps "$@"
            ;;
        "volume")
            case "$2" in
                "ls")
                    mock_docker_volume_ls
                    ;;
                "create")
                    shift 2
                    mock_docker_volume_create "$@"
                    ;;
            esac
            ;;
        "exec")
            shift
            mock_docker_exec "$@"
            ;;
        "run")
            shift
            mock_docker_run "$@"
            ;;
        "rm")
            shift
            mock_docker_rm "$@"
            ;;
        "start")
            shift
            mock_docker_start "$@"
            ;;
        "image")
            case "$2" in
                "inspect")
                    shift 2
                    mock_docker_image_inspect "$@"
                    ;;
            esac
            ;;
        "pull")
            shift
            mock_docker_pull "$@"
            ;;
        "network")
            case "$2" in
                "ls")
                    shift 2
                    mock_docker_network_ls "$@"
                    ;;
                *)
                    echo "Unknown docker network command: $2"
                    return 1
                    ;;
            esac
            ;;
        *)
            echo "Unknown docker command: $1"
            return 1
            ;;
    esac
}

# Reset mock state
reset_docker_mocks() {
    unset MOCK_CONTAINER_EXISTS
    unset MOCK_CONTAINER_RUNNING
    unset MOCK_CONTAINER_NAME
    unset MOCK_VOLUME_EXISTS
    unset MOCK_HOME_FOLDER
    unset MOCK_HOME_EXISTS
    unset MOCK_SHELL
    unset MOCK_SHELL_EXISTS
    unset MOCK_DOCKER_RUN_FAIL
    unset MOCK_CREATED_CONTAINER
    unset MOCK_USED_IMAGE
    unset MOCK_IMAGE_EXISTS_LOCALLY
    unset MOCK_IMAGE_EXISTS_ON_HUB
    unset MOCK_DOCKER_PULL_FAIL
    unset MOCK_NETWORK_EXISTS
    unset MOCK_NETWORK_NAME
}

# Export functions for use in tests
export -f docker
export -f curl
export -f mock_docker_ps
export -f mock_docker_volume_ls
export -f mock_docker_volume_create
export -f mock_docker_exec
export -f mock_docker_run
export -f mock_docker_rm
export -f mock_docker_start
export -f mock_docker_image_inspect
export -f mock_docker_pull
export -f mock_docker_network_ls
export -f reset_docker_mocks