# Container Here

Quick create container with auto mount working dir.

## Table of Contents

- [Requirements](#requirements)
- [Installation](#installation)
- [Quick Start](#quick-start)
- [Features](#features)
- [Usage](#usage)
- [Configuration](#configuration)
- [Resource Management](#resource-management)
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

# List all your containers to see what's available
./container-here --list

# Quickly reconnect to any existing container
./container-here --attach my-project
```

## Features

- **🔧 Configuration Management**: Set default Docker images and custom mount paths in `~/.config/container-here/config`
- **🏷️ Smart Container Naming**: Uses first argument or current folder name with `container-here-` prefix
- **🐳 Flexible Docker Images**: Specify any Docker image with `--image` option (default: from config or `alpine`)
- **✅ Image Validation**: Automatically checks if images exist locally or on Docker Hub
- **📥 Smart Image Pulling**: Prompts user confirmation before pulling images from Docker Hub
- **💾 Persistent Scripts Volume**: Creates and mounts `container-here-user-scripts` volume to `/user-scripts`
- **📁 Custom Mount Paths**: Mount host directories with configurable read-only/read-write permissions
- **🌐 Network Connectivity**: Connect containers to Docker networks for service integration
- **🔌 Port Mapping**: Map host ports to container ports for service access
- **🔄 Container Persistence**: Containers persist after exit - no more lost work!
- **📋 Container Management**: List, attach, and manage existing containers easily
- **🔗 Quick Reconnection**: Attach to any existing container with `--attach` command
- **📊 Status Monitoring**: View all containers with their status and mounted directories
- **🐚 Shell Detection**: Automatically detects and uses container's configured shell

## Usage

```bash
# Show help
./container-here --help
```

```
Usage: container-here [OPTIONS] [CONTAINER_NAME]

Quick create container with auto mount working dir.

Arguments:
  CONTAINER_NAME    Name for the container (default: current folder name)

Options:
  --image IMAGE     Docker image to use (default: from config or alpine)
  --mount PATH      Mount host path to container: /host/path:/container/path[:mode]
                    Mode can be 'rw' (read-write) or 'ro' (read-only). Default: rw
                    Can be used multiple times for multiple mounts
  --mount-ro PATH   Mount host path as read-only: /host/path:/container/path
                    Shorthand for --mount /host/path:/container/path:ro
  --network NAME    Connect container to Docker network (can be used multiple times)
  --port MAPPING    Map host port to container port: host_port:container_port[:protocol]
                    Protocol can be 'tcp' (default), 'udp', or 'sctp'
                    Can be used multiple times for multiple ports
  --cpu NUMBER      Limit CPU usage (e.g., 1, 1.5, 2.0)
  --memory SIZE     Limit memory usage (e.g., 512m, 1g, 2G)
  --list            List all container-here containers and their status
  --attach NAME     Attach to existing container by name
  --config          Show configuration management options
  view-scripts [OPTIONS]  View content of the scripts volume using temporary container
    --alpine        Force use of Alpine image for viewing scripts
    --image IMAGE   Use specific image for viewing scripts
  -h, --help        Show this help message

Examples:
  container-here                          # Use current folder name with default image
  container-here my-app                   # Use 'my-app' as name with default image
  container-here --image ubuntu my-app    # Use ubuntu image with 'my-app' as name
  container-here --mount /data:/app/data my-app   # Mount /data to /app/data (read-write)
  container-here --mount-ro /config:/app/config my-app # Mount /config to /app/config (read-only)
  container-here --mount /data:/data:ro --mount /logs:/logs:rw my-app # Multiple mounts
  container-here --network my-network my-app     # Connect to Docker network
  container-here --port 8080:80 my-app           # Map host port 8080 to container port 80
  container-here --port 8080:80:tcp --port 9090:9090:udp my-app # Multiple port mappings
  container-here --cpu 2 --memory 1g my-app      # Limit to 2 CPUs and 1GB memory
  container-here --cpu 1.5 my-app                # Limit to 1.5 CPUs
  container-here --memory 512m my-app            # Limit to 512MB memory
  container-here --list                   # List all container-here containers
  container-here --attach my-app          # Attach to existing 'my-app' container
  container-here view-scripts             # View content of scripts volume (uses config default or alpine)
  container-here view-scripts --alpine   # View scripts using Alpine image
  container-here view-scripts --image ubuntu:22.04  # View scripts using Ubuntu image
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

# Mount additional directories for data access
./container-here --mount /home/user/data:/app/data my-app

# Mount configuration files as read-only
./container-here --mount-ro /etc/myconfig:/app/config my-app

# Multiple custom mounts with different permissions
./container-here --mount /home/user/data:/app/data:rw --mount-ro /home/user/config:/app/config my-app

# Connect container to Docker network
./container-here --network my-network my-app

# Connect to multiple networks
./container-here --network frontend --network backend my-app

# Map ports for web development
./container-here --port 3000:3000 --port 8080:80 web-app

# Map ports with specific protocols
./container-here --port 8080:80:tcp --port 5432:5432:tcp database-app

# List all your containers with their status and directories
./container-here --list

# Attach to an existing container (starts if stopped)
./container-here --attach my-app

# View scripts volume content
./container-here view-scripts
```

## Command Line Reference

### Main Options

- `--image IMAGE`: Specify Docker image to use (default: from config or `alpine`)
- `--mount PATH`: Mount host path to container with format `/host/path:/container/path[:mode]`
  - Mode can be `rw` (read-write) or `ro` (read-only)
  - Default mode is `rw` if not specified
  - Can be used multiple times for multiple mounts
- `--mount-ro PATH`: Mount host path as read-only with format `/host/path:/container/path`
  - Shorthand for `--mount /host/path:/container/path:ro`
- `--network NAME`: Connect container to Docker network
  - Can be used multiple times to connect to multiple networks
  - Shows warning if network doesn't exist but continues
- `--port MAPPING`: Map host port to container port with format `host_port:container_port[:protocol]`
  - Protocol can be `tcp` (default), `udp`, or `sctp`
  - Can be used multiple times for multiple port mappings
  - Example: `--port 8080:80` or `--port 8080:80:tcp`
- `--list`: List all container-here containers with status and mounted directories
- `--attach NAME`: Attach to existing container by name (starts if stopped)
- `--config`: Show configuration management options or manage settings
- `view-scripts [OPTIONS]`: View content of the scripts volume using temporary container
  - `--alpine`: Force use of Alpine image for viewing scripts
  - `--image IMAGE`: Use specific image for viewing scripts
- `-h, --help`: Show usage information
- `CONTAINER_NAME`: Optional container name (default: current folder name)

### Configuration Commands

- `--config set [--global] <key> <value>`: Set a configuration value (local by default)
- `--config get <key>`: Get a configuration value
- `--config list`: List all configuration values
- `--config which <key>`: Show which config source provides a value
- `--config sources`: List all config sources in precedence order
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

## Container Persistence & Management

### Container Persistence

**🎉 New in latest version**: Containers now persist after you exit the shell! No more lost work when you accidentally exit.

- Containers are created **without** the `--rm` flag, so they remain available after exit
- All your work, installed packages, and configurations are preserved
- Simply reconnect to continue where you left off

### Container Management Commands

#### List All Containers
```bash
./container-here --list
```

Example output:
```
Container-here containers:

NAME                    STATUS                  MOUNTED DIRECTORY
my-project             Up 2 hours              /Users/john/projects/my-project
data-analysis          Exited (0) 5 minutes ago /Users/john/data/analysis
web-dev                Up 1 day                /Users/john/sites/webapp

To attach to a container: container-here --attach <name>
To create a new container: container-here [name]
```

#### Attach to Existing Container
```bash
# Attach to a running container
./container-here --attach my-project

# Attach to a stopped container (automatically starts it)
./container-here --attach data-analysis
```

### Existing Container Behavior

When a container with the same name already exists, you'll be prompted with options:

1. **Exit** - Stop the script
2. **Remove old container** - Delete existing container and create new one  
3. **Use existing container** - Start/attach to existing container (shows current status)

## Configuration

Container Here supports multi-level configuration with clear precedence rules, allowing both project-specific and user-wide settings.

### Configuration Hierarchy (Highest to Lowest Priority)

1. **Command-line arguments** - Override all configurations
2. **Environment variables** - Runtime overrides (e.g., `CONTAINER_HERE_DEFAULT_IMAGE`)
3. **Local project config** - `.container-here.conf` in current directory
4. **Global/User config** - `~/.config/container-here/config`
5. **Built-in defaults** - Hardcoded fallback values

### Configuration Management

```bash
# Show configuration help
./container-here --config
```

```
Configuration Management:

Commands:
  container-here --config set [--global] <key> <value>    Set a configuration value
  container-here --config get <key>                       Get a configuration value
  container-here --config list                            List all configuration values
  container-here --config which <key>                     Show which config source provides a value
  container-here --config sources                         List all config sources in precedence order

Configuration keys:
  default_image              Default Docker image to use (default: alpine)
  custom_mounts              Custom mount definitions in JSON format
                            Format: [{"host":"/path","container":"/path","mode":"rw|ro"}]
  port_mappings              Port mapping definitions (simple or JSON format)
                            Simple: '8080:80 9090:90:udp'
                            JSON: '[{"host":"8080","container":"80","protocol":"tcp"}]'

Examples:
  # Set local project config (default)
  container-here --config set default_image node:18
  
  # Set global/user config
  container-here --config set --global default_image ubuntu:22.04
  
  # Check which config provides a value
  container-here --config which default_image
  
  # Set port mappings (simple format)
  container-here --config set port_mappings '8080:80 9090:90:udp'
  
  # Override with environment variable
  CONTAINER_HERE_DEFAULT_IMAGE=python:3.11 container-here
```

#### Configuration Commands

```bash
# Set local project config (default behavior like git)
./container-here --config set default_image node:18

# Set global/user config (requires --global flag)
./container-here --config set --global default_image ubuntu:22.04

# Get current value (from any source)
./container-here --config get default_image

# Check which config source provides a value
./container-here --config which default_image
# Output: default_image = node:18
#         Source: local (/path/to/project/.container-here.conf)

# List all configuration sources
./container-here --config sources

# List all configuration values with their sources
./container-here --config list
```

### Environment Variables

Override any configuration value using environment variables:

```bash
# Override default image
CONTAINER_HERE_DEFAULT_IMAGE=python:3.11 ./container-here my-app

# Override custom mounts
CONTAINER_HERE_CUSTOM_MOUNTS='[{"host":"/tmp","container":"/tmp","mode":"rw"}]' ./container-here
```

### Local Project Configuration

Create a `.container-here.conf` file in your project root for project-specific settings:

```bash
# .container-here.conf
default_image=node:18-alpine
custom_mounts=[{"host":"./src","container":"/app/src","mode":"rw"},{"host":"./config","container":"/app/config","mode":"ro"}]
```

This file can be committed to version control, allowing team members to share the same container configuration.

### Available Configuration Keys

- `default_image`: Default Docker image to use (default: `alpine`)
- `custom_mounts`: Custom mount definitions in JSON format for persistent mount configurations
- `port_mappings`: Port mapping definitions in simple or JSON format for persistent port configurations
- `cpu_limit`: Default CPU limit for containers (e.g., `1`, `1.5`, `2.0`)
- `memory_limit`: Default memory limit for containers (e.g., `512m`, `1g`, `2G`)

### Volume Mounting

Container Here automatically mounts:
- Current working directory to `/app` in the container (read-write)
- Persistent volume `container-here-user-scripts` to `/user-scripts` for storing scripts and data across container sessions (read-write)

Additionally, you can configure custom mounts:
- **Via CLI flags**: Use `--mount` and `--mount-ro` flags for one-time custom mounts
- **Via configuration**: Set persistent custom mounts using the `custom_mounts` configuration key
- **Mount modes**: Support for both read-write (`rw`) and read-only (`ro`) permissions
- **Path validation**: Automatic validation of host paths (must exist) and container paths (must be absolute)

### Configuration File Format

The configuration file uses a simple `key=value` format:

```
default_image=ubuntu:22.04
custom_mounts=[{"host":"/home/user/data","container":"/app/data","mode":"rw"},{"host":"/etc/configs","container":"/app/config","mode":"ro"}]
```

### Configuration Workflow Examples

#### Multi-Level Configuration Example

```bash
# 1. Set global/user-wide defaults
./container-here --config set --global default_image ubuntu:22.04
./container-here --config set --global custom_mounts '[{"host":"/home/user/data","container":"/data","mode":"rw"}]'

# 2. Set project-specific overrides (default behavior)
cd /path/to/nodejs-project
./container-here --config set default_image node:18-alpine
./container-here --config set custom_mounts '[{"host":"./src","container":"/app/src","mode":"rw"}]'

# 3. Check which configuration is active
./container-here --config which default_image
# Output: default_image = node:18-alpine
#         Source: local (/path/to/nodejs-project/.container-here.conf)

# 4. List all configurations with sources
./container-here --config list
# Output shows both local and global configs with source indicators

# 5. Override with environment variable for one-off use
CONTAINER_HERE_DEFAULT_IMAGE=python:3.11 ./container-here test-python

# 6. View configuration hierarchy
./container-here --config sources
```

#### Team Collaboration Example

```bash
# Project lead sets up local config
echo 'default_image=node:18-alpine' > .container-here.conf
echo 'custom_mounts=[{"host":"./src","container":"/app/src","mode":"rw"}]' >> .container-here.conf

# Commit to version control
git add .container-here.conf
git commit -m "Add container configuration for team"

# Team members automatically get the same environment
git pull
./container-here dev-env    # Uses project-specific configuration
```

## Resource Management

Container Here supports CPU and memory resource limits to control container resource usage and ensure predictable performance.

### Resource Configuration Options

#### CLI Resource Flags

```bash
# Limit CPU usage to 2 cores
./container-here --cpu 2 my-app

# Limit memory to 1GB
./container-here --memory 1g my-app

# Combine CPU and memory limits
./container-here --cpu 1.5 --memory 512m my-app

# Use fractional CPU limits
./container-here --cpu 0.5 my-app  # Half CPU core
```

#### Configuration-Based Resource Limits

Set persistent resource limits using the configuration system:

```bash
# Set default CPU limit for all containers
./container-here --config set cpu_limit 2.0

# Set default memory limit for all containers  
./container-here --config set memory_limit 1g

# Set global defaults
./container-here --config set --global cpu_limit 1.5
./container-here --config set --global memory_limit 2g

# View current resource configuration
./container-here --config list
```

#### Environment Variable Overrides

```bash
# Override resource limits with environment variables
CONTAINER_HERE_CPU_LIMIT=3 ./container-here my-app
CONTAINER_HERE_MEMORY_LIMIT=2g ./container-here my-app
```

### Resource Limit Formats

#### CPU Limits
- Integer values: `1`, `2`, `4` (number of CPU cores)
- Decimal values: `0.5`, `1.5`, `2.5` (fractional CPU cores)
- Docker equivalent: `--cpus` flag

#### Memory Limits
- Numbers with units: `512m`, `1g`, `2G`, `1024M`
- Raw numbers: `1073741824` (bytes)
- Supported units: `b` (bytes), `k` (KB), `m` (MB), `g` (GB)
- Docker equivalent: `--memory` flag

### Configuration Hierarchy

Resource limits follow the same configuration hierarchy as other settings:

1. **CLI arguments** (`--cpu`, `--memory`) - highest priority
2. **Environment variables** (`CONTAINER_HERE_CPU_LIMIT`, `CONTAINER_HERE_MEMORY_LIMIT`)
3. **Local project config** (`.container-here.conf`)
4. **Global user config** (`~/.config/container-here/config`)
5. **No limits** (default behavior)

### Resource Management Examples

#### Development Environment with Resource Limits

```bash
# Set up a resource-constrained development environment
./container-here --config set cpu_limit 1.5
./container-here --config set memory_limit 1g
./container-here --config set default_image node:18

# All containers will now use these resource limits
./container-here frontend-app    # Uses 1.5 CPU, 1GB memory
./container-here backend-api     # Uses 1.5 CPU, 1GB memory

# Override for specific containers
./container-here --cpu 2 --memory 2g build-server
```

#### Team Configuration for Consistent Resource Usage

```bash
# Project lead sets up resource constraints
echo 'cpu_limit=1.5' > .container-here.conf
echo 'memory_limit=1g' >> .container-here.conf
echo 'default_image=node:18-alpine' >> .container-here.conf

# Commit to version control
git add .container-here.conf
git commit -m "Add resource limits for consistent development environment"

# Team members get consistent resource usage
git pull
./container-here dev-env  # Automatically applies CPU and memory limits
```

## Port Mapping

Container Here supports comprehensive port mapping to expose container services to the host system. Port mappings can be configured via CLI arguments or persistent configuration.

### Port Mapping Options

#### CLI Port Mapping

```bash
# Map single port (TCP is default)
./container-here --port 8080:80 web-app

# Map multiple ports
./container-here --port 8080:80 --port 3000:3000 web-app

# Specify protocols explicitly
./container-here --port 8080:80:tcp --port 9090:9090:udp app

# Database port mapping
./container-here --port 5432:5432 database-container
```

#### Configuration-Based Port Mapping

Set persistent port mappings using the configuration system:

```bash
# Simple format (recommended)
./container-here --config set port_mappings '8080:80 3000:3000'

# Multiple ports with different protocols
./container-here --config set port_mappings '8080:80:tcp 9090:9090:udp'

# JSON format (for complex scenarios)
./container-here --config set port_mappings '[
  {"host":"8080","container":"80","protocol":"tcp"},
  {"host":"9090","container":"9090","protocol":"udp"}
]'

# View current port configuration
./container-here --config list
```

#### Environment Variable Overrides

```bash
# Override port mappings with environment variables
CONTAINER_HERE_PORT_MAPPINGS='3000:3000 8080:80' ./container-here my-app
```

### Port Mapping Formats

#### Simple Format (Recommended)
- Space-separated port mappings: `8080:80 9090:90:udp`
- Format: `host_port:container_port[:protocol]`
- Default protocol: `tcp`
- Easier to type and read

#### JSON Format
- Full JSON array: `[{"host":"8080","container":"80","protocol":"tcp"}]`
- More verbose but supports all features
- Backward compatibility maintained

### Supported Protocols
- `tcp` (default) - Transmission Control Protocol
- `udp` - User Datagram Protocol  
- `sctp` - Stream Control Transmission Protocol

### Port Mapping Examples

#### Web Development Environment
```bash
# Frontend and backend development
./container-here --config set port_mappings '3000:3000 8080:80 5432:5432'
./container-here --config set default_image node:18

# All web containers get these ports
./container-here frontend-app     # Ports 3000, 8080, 5432 mapped
./container-here backend-api      # Same ports automatically mapped

# Override for specific containers
./container-here --port 9000:9000 special-service
```

#### Database Services
```bash
# PostgreSQL container
./container-here --port 5432:5432 --image postgres:15 database

# Redis container with different host port
./container-here --port 6380:6379 --image redis:alpine cache

# Multiple database instances
./container-here --port 5433:5432 postgres-test
./container-here --port 5434:5432 postgres-staging
```

#### Microservices Architecture
```bash
# Set up port mappings for microservices
./container-here --config set port_mappings '8001:8000 8002:8000 8003:8000'

# Each service gets its own port
./container-here --port 8001:8000 user-service
./container-here --port 8002:8000 order-service
./container-here --port 8003:8000 payment-service
```

### Configuration Hierarchy

Port mappings follow the same configuration hierarchy as other settings:

1. **CLI arguments** (`--port`) - highest priority
2. **Environment variables** (`CONTAINER_HERE_PORT_MAPPINGS`)
3. **Local project config** (`.container-here.conf`)
4. **Global user config** (`~/.config/container-here/config`)
5. **No port mappings** (default behavior)

### Team Configuration Example

```bash
# Project lead sets up port mappings for team
echo 'port_mappings=3000:3000 8080:80' > .container-here.conf
echo 'default_image=node:18-alpine' >> .container-here.conf

# Commit to version control
git add .container-here.conf
git commit -m "Add port mapping configuration for team"

# Team members get consistent port mappings
git pull
./container-here dev-env  # Automatically maps ports 3000 and 8080
```

## Volume Mounting

### Default Mounts
- Current directory → `/app` (in container, read-write)
- `container-here-user-scripts` volume → `/user-scripts` (in container, read-write)

### Custom Mount Options

#### CLI Mount Flags
```bash
# Mount directory with read-write access
./container-here --mount /host/data:/container/data my-app

# Mount directory as read-only
./container-here --mount-ro /host/configs:/container/configs my-app

# Multiple mounts with mixed permissions
./container-here --mount /data:/app/data:rw --mount-ro /configs:/app/config my-app
```

#### Configuration-Based Mounts
```bash
# Set persistent custom mounts
./container-here --config set custom_mounts '[
  {"host":"/home/user/projects","container":"/workspace","mode":"rw"},
  {"host":"/etc/ssl/certs","container":"/app/certs","mode":"ro"}
]'

# All future containers will use these mounts automatically
./container-here my-project
```

#### Mount Validation
- **Host paths**: Must exist on the host system
- **Container paths**: Must be absolute paths (start with `/`)
- **Mount modes**: Only `rw` (read-write) and `ro` (read-only) are supported
- **CLI override**: CLI mount flags override configuration-based mounts

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
- ✅ Custom mount path functionality
- ✅ Container name generation
- ✅ Container existence checking
- ✅ Volume creation logic
- ✅ User input handling
- ✅ Shell detection for existing containers
- ✅ Command line argument parsing (`--image`, `--mount`, `--mount-ro`, `--help`)
- ✅ Error handling for invalid options
- ✅ Image validation (local and Docker Hub checks)
- ✅ Docker Hub URL generation
- ✅ Image pulling functionality
- ✅ Mount validation and configuration parsing

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

# Set up common web development ports
./container-here --config set port_mappings '3000:3000 8080:80 9000:9000'

# Now create containers for different projects
./container-here frontend-app       # Uses node:18-alpine with ports mapped
./container-here api-server         # Uses node:18-alpine with ports mapped
./container-here --image nginx web-proxy  # Override for specific needs

# Create containers with specific port mappings
./container-here --port 3001:3000 --port 8081:80 frontend-alt
```

#### Data Science Workflow

```bash
# Set Python as default for data work
./container-here --config set default_image python:3.11-slim

# Set up persistent mounts for data and notebooks
./container-here --config set custom_mounts '[
  {"host":"/home/user/datasets","container":"/data","mode":"ro"},
  {"host":"/home/user/notebooks","container":"/notebooks","mode":"rw"}
]'

# Create containers for different analyses
./container-here data-analysis      # Uses python:3.11-slim with data mounts
./container-here ml-experiments     # Uses python:3.11-slim with data mounts

# Override with specific mounts for special projects
./container-here --mount /home/user/large-dataset:/data:ro --image jupyter/scipy-notebook research
```

#### DevOps and System Administration

```bash
# Set Ubuntu as default for system work
./container-here --config set default_image ubuntu:22.04

# Mount common configuration directories
./container-here --mount-ro /etc/ssl:/etc/ssl --mount /var/log:/logs server-config

# Quick debugging with minimal tools
./container-here --image alpine:latest --mount-ro /etc/hosts:/etc/hosts minimal-debug

# Container with access to Docker socket (for Docker-in-Docker workflows)
./container-here --mount /var/run/docker.sock:/var/run/docker.sock:rw docker-tools
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

### Persistent Workflow Examples

#### Daily Development Routine

```bash
# Monday: Start new project
./container-here --image node:18 new-app
# Install dependencies, write code, exit accidentally...

# Tuesday: Continue where you left off
./container-here --list
# Shows: new-app | Exited (0) 16 hours ago | /Users/you/projects/new-app
./container-here --attach new-app
# Back to your environment with all packages still installed!

# Wednesday: Check all active projects
./container-here --list
# Shows all containers with their directories and status
```

#### Project Switching

```bash
# Work on frontend (React)
./container-here --attach frontend-app
# Work for a while, then switch to backend

# Switch to backend API (Python)  
./container-here --attach api-server
# Both environments stay ready with all your work preserved

# Quick status check
./container-here --list
# See which projects are running vs stopped
```

#### Long-Running Development

```bash
# Start development environment
./container-here --image ubuntu:22.04 dev-environment
# Install tools, configure environment, set up dotfiles...

# Weeks later, instantly return to configured environment
./container-here --attach dev-environment
# Everything exactly as you left it - no setup needed!
```

### Database and Services

```bash
# Using specialized images with port mappings (will prompt to pull if not local)
./container-here --port 5432:5432 --image postgres:15 database-work
./container-here --port 6379:6379 --image redis:alpine cache-testing
./container-here --port 27017:27017 --image mongo:6 document-db
./container-here --port 80:80 --port 443:443 --image nginx:alpine web-server

# Multiple database instances with different host ports
./container-here --port 5433:5432 --image postgres:15 postgres-test
./container-here --port 5434:5432 --image postgres:15 postgres-prod
```

## Custom Mount Path Examples

### Development Environment Setup

```bash
# Mount source code, build artifacts, and configuration
./container-here \
  --mount /home/user/projects:/workspace:rw \
  --mount-ro /home/user/.gitconfig:/root/.gitconfig \
  --mount /home/user/.ssh:/root/.ssh:ro \
  --image ubuntu:22.04 dev-env
```

### Database Container with Persistent Data

```bash
# Mount database data directory and config files
./container-here \
  --mount /var/lib/mysql:/var/lib/mysql:rw \
  --mount-ro /etc/mysql/my.cnf:/etc/mysql/my.cnf \
  --image mysql:8.0 database
```

### Web Server with Content and Logs

```bash
# Mount web content as read-only, logs as read-write
./container-here \
  --mount-ro /home/user/website:/var/www/html \
  --mount /var/log/nginx:/var/log/nginx:rw \
  --image nginx:alpine web-server
```

### Data Processing Pipeline

```bash
# Mount input data as read-only, output directory as read-write
./container-here \
  --mount-ro /data/input:/app/input \
  --mount /data/output:/app/output:rw \
  --mount-ro /config/pipeline.yaml:/app/config.yaml \
  --image python:3.11 data-processor
```

### Configuration-Based Persistent Setup

```bash
# Set up a development environment with persistent mounts
./container-here --config set custom_mounts '[
  {"host":"/home/user/projects","container":"/workspace","mode":"rw"},
  {"host":"/home/user/.gitconfig","container":"/root/.gitconfig","mode":"ro"},
  {"host":"/home/user/.ssh","container":"/root/.ssh","mode":"ro"},
  {"host":"/home/user/bin","container":"/usr/local/bin","mode":"ro"}
]'

# Now all containers automatically get these mounts
./container-here my-project      # Automatically includes all configured mounts
./container-here another-project # Same persistent mounts applied
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
