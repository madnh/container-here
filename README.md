# Container Here

Quick create container with auto mount working dir.

## Table of Contents

- [Requirements](#requirements)
- [Installation](#installation)
- [Quick Start](#quick-start)
- [Features](#features)
- [Usage](#usage)
- [Configuration](#configuration)
- [Command Line Reference](#command-line-reference)
- [Real-World Examples](#real-world-examples)
- [Container Management](#container-management)
- [Image Validation Process](#image-validation-process)
- [Volume Mounting](#volume-mounting)
- [Testing](#testing)
- [Error Handling](#error-handling)
- [Development](#development)

## Requirements

- Docker
- Bash 3.2+
- `curl` (for Docker Hub API checks)
- BATS (for testing, optional)

## Installation

### Quick Install

1. Clone or download the script
2. Make it executable: `chmod +x container-here`
3. Move it to where can found by `$PATH`
4. Run: `container-here [container-name]`

### Add to PATH (Recommended)

For easier access from anywhere:

```bash
# Copy to a directory in your PATH
cp container-here $HOME/bin/

# Or create a symlink
sudo ln -s /path/to/container-here /usr/local/bin/container-here

# Now you can run from anywhere
container-here --help
```

## Quick Start

```bash
# Create a container with current folder name using default alpine image
./container-here

# Create a container with custom name
./container-here my-project

# Use a specific Docker image
./container-here --image ubuntu:22.04 my-ubuntu-project

# Set defaults to avoid typing options every time
./container-here --config set default_image ubuntu:22.04
./container-here my-project  # Now uses ubuntu:22.04 automatically
```

## Features

- **🔧 Configuration Management**: Set default Docker images in `~/.config/container-here/config`
- **🏷️ Smart Container Naming**: Uses first argument or current folder name with `container-here-` prefix
- **🐳 Flexible Docker Images**: Specify any Docker image with `--image` option (default: from config or `alpine`)
- **✅ Image Validation**: Automatically checks if images exist locally or on Docker Hub
- **📥 Smart Image Pulling**: Prompts user confirmation before pulling images from Docker Hub
- **💾 Persistent Scripts Volume**: Creates and mounts `container-here-user-scripts` volume to `/user-scripts`
- **📋 Container Management**: Handles existing containers with user-friendly options
- **🐚 Shell Detection**: Automatically detects and uses container's configured shell

## Usage

```bash
# Show help
./container-here --help
```

```
Usage: container-here [OPTIONS] [CONTAINER_NAME]

Create and manage Docker containers for development environments.

Arguments:
  CONTAINER_NAME    Name for the container (default: current folder name)

Options:
  --image IMAGE     Docker image to use (default: from config or alpine)
  --config          Show configuration management options
  view-scripts      View content of the scripts volume using temporary Alpine container
  -h, --help        Show this help message

Examples:
  container-here                          # Use current folder name with default image
  container-here my-app                   # Use 'my-app' as name with default image
  container-here --image ubuntu my-app    # Use ubuntu image with 'my-app' as name
  container-here --home /root my-app      # Mount volume to /root instead of auto-detected home
```

### Basic Usage Examples

```bash
# Use current folder name with default image (alpine or your configured default)
./container-here

# Specify custom container name with default image
./container-here my-app

# Use specific Docker image (overrides default)
./container-here --image ubuntu:22.04 my-app

# Use Node.js image with current folder name
./container-here --image node:18

# Use Python image for data science work
./container-here --image python:3.11-slim data-analysis

# View scripts volume content
./container-here view-scripts
```

## Command Line Reference

### Main Options

- `--image IMAGE`: Specify Docker image to use (default: from config or `alpine`)
- `--config`: Show configuration management options or manage settings
- `view-scripts`: View content of the scripts volume using temporary Alpine container
- `-h, --help`: Show usage information
- `CONTAINER_NAME`: Optional container name (default: current folder name)

### Configuration Commands

- `--config set <key> <value>`: Set a configuration value
- `--config get <key>`: Get a configuration value
- `--config list`: List all configuration values
- `--config`: Show configuration help
## Image Validation Process

The script automatically validates Docker images through the following process:

1. **Local Check**: First checks if the image exists locally
2. **Docker Hub Check**: If not local, queries Docker Hub API to verify existence
3. **User Confirmation**: Shows Docker Hub URL and asks for permission to pull
4. **Automatic Pull**: Downloads the image if user confirms
5. **Error Handling**: Provides clear error messages for non-existent images

### Example Image Validation Flow

```bash
$ ./container-here --image python:3.11

Checking Docker image: python:3.11
Image 'python:3.11' not found locally, checking Docker Hub...
✓ Image 'python:3.11' found on Docker Hub
Docker Hub URL: https://hub.docker.com/_/python

Do you want to pull this image? (y/N): y
Pulling image 'python:3.11'...
✓ Image 'python:3.11' pulled successfully
```

## Container Management

When a container with the same name already exists, you'll be prompted with options:

1. **Exit** - Stop the script
2. **Remove old container** - Delete existing container and create new one
3. **Use existing container** - Start/attach to existing container

## Configuration

Container Here supports persistent configuration through `~/.config/container-here/config`. You can set default values to avoid specifying them every time.

### Configuration Management

```bash
# Show configuration help
./container-here --config
```

```
Configuration Management:

  container-here --config set <key> <value>    Set a configuration value
  container-here --config get <key>            Get a configuration value
  container-here --config list                 List all configuration values

Available configuration keys:
  default_image              Default Docker image to use (default: alpine)
  home <image> <path>        Set home directory for specific image

Examples:
  container-here --config set default_image ubuntu:22.04
  container-here --config get default_image
  container-here --config list
```

#### Configuration Commands

```bash
# Set default Docker image
./container-here --config set default_image ubuntu:22.04

# Get current default image
./container-here --config get default_image

# List all configuration values
./container-here --config list
```

### Available Configuration Keys

- `default_image`: Default Docker image to use (default: `alpine`)

### Volume Mounting

Container Here automatically mounts:
- Current working directory to `/app` in the container
- Persistent volume `container-here-user-scripts` to `/user-scripts` for storing scripts and data across container sessions

### Configuration File Format

The configuration file uses a simple `key=value` format:

```
default_image=ubuntu:22.04
home_ubuntu=/home/ubuntu
home_alpine=/root
home_node_18=/home/node
```

### Configuration Workflow Examples

```bash
# 1. Set your preferred defaults (one-time setup)
./container-here --config set default_image ubuntu:22.04
./container-here --config set home ubuntu /home/ubuntu
./container-here --config set home alpine /root
./container-here --config set home node:18 /home/node

# 2. Verify the settings
./container-here --config get default_image
# Output: ubuntu:22.04

# 3. Now containers use the configured default image automatically
./container-here my-web-project                    # Uses ubuntu:22.04
./container-here --image alpine alpine-tools      # Uses alpine
./container-here --image node:18 js-project       # Uses node:18

# 4. View all your settings
./container-here --config list
```

## Volume Mounting

- Current directory → `/app` (in container)
- `container-here-user-scripts` volume → `/user-scripts` (in container)

## Testing

The project includes comprehensive unit tests using BATS (Bash Automated Testing System).

### Running Tests

```bash
# Run all tests
./run-tests.sh

# Run specific test
bats tests/test_container_here.bats -f "test name"
```

### Test Coverage

- ✅ Volume mounting logic
- ✅ Container name generation
- ✅ Container existence checking
- ✅ Volume creation logic
- ✅ User input handling
- ✅ Shell detection for existing containers
- ✅ Command line argument parsing (`--image`, `--help`)
- ✅ Error handling for invalid options
- ✅ Image validation (local and Docker Hub checks)
- ✅ Docker Hub URL generation
- ✅ Image pulling functionality

### Test Structure

```
tests/
├── test_container_here.bats          # Main test suite
├── helpers/
│   ├── docker_mock.bash             # Docker command mocks
│   └── test_helpers.bash            # Common test utilities
└── fixtures/
    ├── mock_containers.txt          # Sample docker ps output
    └── mock_volumes.txt             # Sample docker volume ls output
```

## Real-World Examples

### Quick Start (Default Alpine)

```bash
# Start with default alpine image
./container-here                    # Creates container-here-<current-folder>
./container-here my-tools           # Creates container-here-my-tools
```

### Development Workflows

#### Web Development Setup

```bash
# Set Node.js as your default for web projects
./container-here --config set default_image node:18-alpine

# Now create containers for different projects
./container-here frontend-app       # Uses node:18-alpine
./container-here api-server         # Uses node:18-alpine
./container-here --image nginx web-proxy  # Override for specific needs
```

#### Data Science Workflow

```bash
# Set Python as default for data work
./container-here --config set default_image python:3.11-slim

# Create containers for different analyses
./container-here data-analysis      # Uses python:3.11-slim
./container-here ml-experiments     # Uses python:3.11-slim
./container-here --image jupyter/scipy-notebook research  # Jupyter for notebooks
```

#### DevOps and System Administration

```bash
# Set Ubuntu as default for system work
./container-here --config set default_image ubuntu:22.04

# Create containers for different tasks
./container-here server-config      # Uses ubuntu:22.04
./container-here network-tools      # Uses ubuntu:22.04
./container-here --image alpine:latest minimal-debug  # Lightweight debugging
```

### Multi-Language Development

```bash
# Switch defaults as needed
./container-here --config set default_image python:3.11
./container-here python-api

./container-here --config set default_image node:18
./container-here react-frontend

./container-here --config set default_image golang:1.21
./container-here go-microservice

# Or override without changing defaults
./container-here --image rust:1.75 rust-project
./container-here --image openjdk:17 java-app
```

### Database and Services

```bash
# Using specialized images (will prompt to pull if not local)
./container-here --image postgres:15 database-work
./container-here --image redis:alpine cache-testing
./container-here --image mongo:6 document-db
./container-here --image nginx:alpine web-server
```

## Error Handling

The script provides helpful error messages for common issues:

- **Invalid image names**: Clear error with suggestion to check Docker Hub
- **Network issues**: Graceful handling of Docker Hub API failures
- **Pull failures**: Informative messages when image downloads fail
- **User cancellation**: Respectful handling when user declines to pull images

## Development

The script is designed to be testable and maintainable:

- Functions are separated for easy testing
- Docker commands are mockable for unit tests
- Test mode prevents script execution during testing
- Comprehensive error handling and user feedback
