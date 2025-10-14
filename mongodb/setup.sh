#!/bin/bash
set -eE -o functrace

failure() {
  local lineno=$1
  local msg=$2
  echo "Failed at $0 line $lineno: $msg"
}
trap 'failure $LINENO "$BASH_COMMAND"' ERR

SCRIPT_DIR=$(dirname "$(readlink -f "$0")")

cd "$HOME"

DEFAULT_PROJECT_DIR="/home/$USERNAME/Documents/code"
PROJECT_DIR=${1:-$DEFAULT_PROJECT_DIR}

# Environment variables with defaults
MONGODB_DATA_DIR=${MONGODB_DATA_DIR:-"$PROJECT_DIR/.mongodb/data"}
MONGODB_HOST_PORT=${MONGODB_HOST_PORT:-27017}
MONGODB_TAG=${MONGODB_TAG:-latest}

# Check docker is installed
if ! command -v docker &> /dev/null; then
    echo "[$PROJECT_DIR] Docker is not installed. Please install Docker first."
    exit 1
fi

# Create mongodb data directory if it doesn't exist
if [ ! -d "$MONGODB_DATA_DIR" ]; then
    mkdir -p "$MONGODB_DATA_DIR"
    echo "[$PROJECT_DIR] Created MongoDB data directory at $MONGODB_DATA_DIR"
fi

# Check if mongodb container already exists
if docker ps -a --format '{{.Names}}' | grep -q '^mongodb-default-container$'; then
    echo "[$PROJECT_DIR] MongoDB container already exists."
    # Check if it's running
    if docker ps --format '{{.Names}}' | grep -q '^mongodb-default-container$'; then
        echo "[$PROJECT_DIR] MongoDB container is already running."
    else
        echo "[$PROJECT_DIR] Starting existing MongoDB container..."
        docker start mongodb-default-container
    fi
else
    echo "[$PROJECT_DIR] Creating new MongoDB container..."
    docker run \
      --name mongodb-default-container \
      -v "$MONGODB_DATA_DIR:/data/db" \
      -p ${MONGODB_HOST_PORT}:27017 \
      -d mongo:$MONGODB_TAG

    echo "[$PROJECT_DIR] MongoDB container created and started successfully."
    echo "[$PROJECT_DIR] Data will be persisted in: $MONGODB_DATA_DIR"
    echo "[$PROJECT_DIR] MongoDB is accessible on port: $MONGODB_HOST_PORT"
    echo "[$PROJECT_DIR] Using MongoDB version: $MONGODB_TAG"
    echo "[$PROJECT_DIR] No authentication required (suitable for development)"
    echo "[$PROJECT_DIR] Connection string: mongodb://localhost:$MONGODB_HOST_PORT"
    echo "[$PROJECT_DIR] Connect with: mongosh mongodb://localhost:$MONGODB_HOST_PORT"
fi
