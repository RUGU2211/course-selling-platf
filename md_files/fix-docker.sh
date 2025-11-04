#!/bin/bash
# Quick fix for Docker configuration issue on EC2

echo "=== Fixing Docker Configuration ==="

# Check if daemon.json exists and is problematic
if [ -f /etc/docker/daemon.json ]; then
    echo "Found existing daemon.json, validating..."
    if python3 -m json.tool /etc/docker/daemon.json > /dev/null 2>&1; then
        echo "✓ daemon.json is valid JSON"
    else
        echo "✗ daemon.json has invalid JSON, backing up and removing..."
        sudo mv /etc/docker/daemon.json /etc/docker/daemon.json.backup
    fi
fi

# Try to start Docker
echo "Attempting to start Docker..."
if sudo systemctl start docker; then
    echo "✓ Docker started successfully"
else
    echo "✗ Docker start failed, checking logs..."
    sudo systemctl status docker
    exit 1
fi

# Verify Docker is running
if sudo systemctl is-active --quiet docker; then
    echo "✓ Docker is running"
    docker --version
else
    echo "✗ Docker is not running"
    exit 1
fi

echo "=== Docker Fixed Successfully! ==="

