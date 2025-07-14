#!/bin/bash

# Test runner script for container-here

set -e

echo "Running container-here unit tests..."
echo "=================================="

# Check if bats is installed
if ! command -v bats &> /dev/null; then
    echo "Error: BATS is not installed. Please install it first."
    echo "Run: git clone https://github.com/bats-core/bats-core.git /tmp/bats-core && cd /tmp/bats-core && sudo ./install.sh /usr/local"
    exit 1
fi

# Run the tests
cd "$(dirname "$0")"

echo "Running tests with BATS..."
echo ""

echo "Running container tests..."
bats tests/test_container_here.bats

echo ""
echo "Running configuration tests..."
bats tests/test_config.bats

echo ""
echo "Test run completed!"
echo ""
echo "To run tests manually:"
echo "  bats tests/test_container_here.bats"
echo "  bats tests/test_config.bats"
echo ""
echo "To run specific test:"
echo "  bats tests/test_container_here.bats -f 'test name'"
echo "  bats tests/test_config.bats -f 'test name'"