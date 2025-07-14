#!/usr/bin/env bats

# Load test helpers
load helpers/docker_mock
load helpers/test_helpers

setup() {
    setup_test_env
    
    # Create temporary directories for testing
    export TEST_HOME="$BATS_TMPDIR/test-home"
    export TEST_PROJECT="$BATS_TMPDIR/test-project"
    mkdir -p "$TEST_HOME/.config/container-here"
    mkdir -p "$TEST_PROJECT"
    
    # Set config paths to test directories
    export HOME="$TEST_HOME"
    export CONFIG_DIR="$TEST_HOME/.config/container-here"
    export CONFIG_FILE="$CONFIG_DIR/config"
    
    # Change to test project directory
    cd "$TEST_PROJECT"
}

teardown() {
    cleanup_test_env
    rm -rf "$TEST_HOME"
    rm -rf "$TEST_PROJECT"
}

# Test local configuration file detection
@test "find_local_config detects local config file" {
    source "$BATS_TEST_DIRNAME/../container-here"
    
    # Create local config file
    echo "default_image=test-image" > "$TEST_PROJECT/.container-here.conf"
    
    run find_local_config
    [ "$status" -eq 0 ]
    [ "$output" = "$TEST_PROJECT/.container-here.conf" ]
}

@test "find_local_config returns error when no local config exists" {
    source "$BATS_TEST_DIRNAME/../container-here"
    
    run find_local_config
    [ "$status" -eq 1 ]
}

# Test environment variable configuration
@test "get_env_config_value reads from environment variable" {
    source "$BATS_TEST_DIRNAME/../container-here"
    
    export CONTAINER_HERE_DEFAULT_IMAGE="env-image"
    
    run get_env_config_value "default_image"
    [ "$status" -eq 0 ]
    [ "$output" = "env-image" ]
}

@test "get_env_config_value handles uppercase conversion" {
    source "$BATS_TEST_DIRNAME/../container-here"
    
    export CONTAINER_HERE_CUSTOM_MOUNTS='[{"host":"/tmp","container":"/tmp","mode":"rw"}]'
    
    run get_env_config_value "custom_mounts"
    [ "$status" -eq 0 ]
    [ "$output" = '[{"host":"/tmp","container":"/tmp","mode":"rw"}]' ]
}

# Test multi-level configuration precedence
@test "get_config_value_multi respects precedence: env > local > user > default" {
    source "$BATS_TEST_DIRNAME/../container-here"
    
    # Set up configs at all levels
    echo "default_image=user-image" > "$CONFIG_FILE"
    echo "default_image=local-image" > "$TEST_PROJECT/.container-here.conf"
    export CONTAINER_HERE_DEFAULT_IMAGE="env-image"
    
    # Environment should win
    run get_config_value_multi "default_image" "default-image"
    [ "$output" = "env-image" ]
    
    # Without env, local should win
    unset CONTAINER_HERE_DEFAULT_IMAGE
    run get_config_value_multi "default_image" "default-image"
    [ "$output" = "local-image" ]
    
    # Without local, user should win
    rm "$TEST_PROJECT/.container-here.conf"
    run get_config_value_multi "default_image" "default-image"
    [ "$output" = "user-image" ]
    
    # Without user, default should be returned
    rm "$CONFIG_FILE"
    run get_config_value_multi "default_image" "default-image"
    [ "$output" = "default-image" ]
}

# Test configuration source identification
@test "get_config_source identifies environment variable source" {
    source "$BATS_TEST_DIRNAME/../container-here"
    
    export CONTAINER_HERE_DEFAULT_IMAGE="env-image"
    
    run get_config_source "default_image"
    [ "$status" -eq 0 ]
    [ "$output" = "environment (CONTAINER_HERE_DEFAULT_IMAGE)" ]
}

@test "get_config_source identifies local config source" {
    source "$BATS_TEST_DIRNAME/../container-here"
    
    echo "default_image=local-image" > "$TEST_PROJECT/.container-here.conf"
    
    run get_config_source "default_image"
    [ "$status" -eq 0 ]
    [ "$output" = "local ($TEST_PROJECT/.container-here.conf)" ]
}

@test "get_config_source identifies global config source" {
    source "$BATS_TEST_DIRNAME/../container-here"
    
    echo "default_image=global-image" > "$CONFIG_FILE"
    
    run get_config_source "default_image"
    [ "$status" -eq 0 ]
    [ "$output" = "global ($CONFIG_FILE)" ]
}

@test "get_config_source returns default when no config exists" {
    source "$BATS_TEST_DIRNAME/../container-here"
    
    run get_config_source "default_image"
    [ "$output" = "default" ]
}

# Test setting configuration values
@test "set_config_value sets local config by default" {
    source "$BATS_TEST_DIRNAME/../container-here"
    
    run set_config_value "default_image" "test-image"
    [ "$status" -eq 0 ]
    
    # Check local file was created and contains the value
    [ -f "$TEST_PROJECT/.container-here.conf" ]
    grep -q "^default_image=test-image$" "$TEST_PROJECT/.container-here.conf"
}

@test "set_config_value sets global config when specified" {
    source "$BATS_TEST_DIRNAME/../container-here"
    
    run set_config_value "default_image" "global-test-image" "global"
    [ "$status" -eq 0 ]
    
    # Check global file was created and contains the value
    [ -f "$CONFIG_FILE" ]
    grep -q "^default_image=global-test-image$" "$CONFIG_FILE"
}

@test "set_config_value overwrites existing values in local config" {
    source "$BATS_TEST_DIRNAME/../container-here"
    
    # Set initial value in local config
    echo "default_image=old-image" > "$TEST_PROJECT/.container-here.conf"
    echo "other_key=value" >> "$TEST_PROJECT/.container-here.conf"
    
    # Update the value (default is local)
    run set_config_value "default_image" "new-image"
    [ "$status" -eq 0 ]
    
    # Check old value is gone and new value exists
    ! grep -q "^default_image=old-image$" "$TEST_PROJECT/.container-here.conf"
    grep -q "^default_image=new-image$" "$TEST_PROJECT/.container-here.conf"
    # Other keys should remain
    grep -q "^other_key=value$" "$TEST_PROJECT/.container-here.conf"
}

# Test list_config_sources function
@test "list_config_sources shows all configuration sources" {
    source "$BATS_TEST_DIRNAME/../container-here"
    
    run list_config_sources
    [ "$status" -eq 0 ]
    [[ "$output" == *"Configuration sources (highest to lowest priority):"* ]]
    [[ "$output" == *"1. Command-line arguments"* ]]
    [[ "$output" == *"2. Environment variables"* ]]
    [[ "$output" == *"3. Local project config"* ]]
    [[ "$output" == *"4. Global/User config"* ]]
    [[ "$output" == *"5. Built-in defaults"* ]]
}

# Test complex custom_mounts configuration
@test "multi-level config handles custom_mounts JSON correctly" {
    source "$BATS_TEST_DIRNAME/../container-here"
    
    local mounts='[{"host":"/data","container":"/app/data","mode":"rw"}]'
    export CONTAINER_HERE_CUSTOM_MOUNTS="$mounts"
    
    run get_config_value_multi "custom_mounts" "[]"
    [ "$status" -eq 0 ]
    [ "$output" = "$mounts" ]
}

# Test backward compatibility
@test "get_config_value wrapper maintains backward compatibility" {
    source "$BATS_TEST_DIRNAME/../container-here"
    
    echo "default_image=compat-image" > "$CONFIG_FILE"
    
    # Old function should still work
    run get_config_value "default_image" "alpine"
    [ "$output" = "compat-image" ]
}

# Test invalid target handling
@test "set_config_value rejects invalid target" {
    source "$BATS_TEST_DIRNAME/../container-here"
    
    run set_config_value "default_image" "test-image" "invalid"
    [ "$status" -eq 1 ]
    [[ "$output" == *"Invalid config target"* ]]
}

# Test new command-line interface
@test "handle_config_command sets local by default" {
    source "$BATS_TEST_DIRNAME/../container-here"
    export BATS_TEST_MODE=1
    
    # Simulate: container-here --config set default_image test-image
    handle_config_command "set" "default_image" "test-image" > /tmp/test_output 2>&1
    
    # Check local file was created
    [ -f "$TEST_PROJECT/.container-here.conf" ]
    grep -q "^default_image=test-image$" "$TEST_PROJECT/.container-here.conf"
}

@test "handle_config_command supports --global flag" {
    source "$BATS_TEST_DIRNAME/../container-here"
    export BATS_TEST_MODE=1
    
    # Simulate: container-here --config set --global default_image global-image
    handle_config_command "set" "--global" "default_image" "global-image" > /tmp/test_output 2>&1
    
    # Check global file was created
    [ -f "$CONFIG_FILE" ]
    grep -q "^default_image=global-image$" "$CONFIG_FILE"
}