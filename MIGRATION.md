# Migration Guide: Configuration System Changes

## Overview

The configuration system has been updated to follow git's configuration model where local configuration is the default target, and global configuration requires an explicit flag.

## What Changed

### Old Behavior
```bash
# Old: User/global config was default
container-here --config set default_image ubuntu:22.04  # Wrote to global config

# Old: Local config required explicit target
container-here --config set local default_image node:18  # Wrote to local config
```

### New Behavior (Git-like)
```bash
# New: Local config is default
container-here --config set default_image node:18  # Writes to local config

# New: Global config requires --global flag
container-here --config set --global default_image ubuntu:22.04  # Writes to global config
```

## Migration Steps

If you have existing configuration commands in scripts or documentation, update them as follows:

1. **For commands that wrote to user/global config** (default behavior):
   - Add `--global` flag to maintain the same behavior
   - Example: `--config set key value` → `--config set --global key value`

2. **For commands that explicitly used `local`**:
   - Remove the `local` keyword (it's now default)
   - Example: `--config set local key value` → `--config set key value`

3. **For commands that explicitly used `user`**:
   - Replace `user` with `--global`
   - Example: `--config set user key value` → `--config set --global key value`

## Benefits

- **Familiar to git users**: Same mental model as `git config`
- **Project-first approach**: Encourages project-specific configurations
- **Clearer intent**: The `--global` flag makes it explicit when you're modifying user-wide settings
- **Simpler syntax**: No need to specify "local" for the most common use case

## Examples

### Setting project-specific configuration
```bash
# Configure for current project only
cd /path/to/my-project
container-here --config set default_image node:18
container-here --config set custom_mounts '[{"host":"./src","container":"/app/src","mode":"rw"}]'
```

### Setting user-wide defaults
```bash
# Configure globally for all projects
container-here --config set --global default_image ubuntu:22.04
container-here --config set --global custom_mounts '[{"host":"/data","container":"/data","mode":"rw"}]'
```

### Checking configuration
```bash
# These commands remain unchanged
container-here --config get default_image
container-here --config which default_image
container-here --config list
container-here --config sources
```

## No Action Required For

- Reading configuration (`--config get`)
- Listing configuration (`--config list`)
- Checking configuration sources (`--config which`, `--config sources`)
- Existing configuration files (they continue to work as before)
- Environment variable overrides (unchanged)

The configuration precedence hierarchy remains the same, only the default write target has changed.