#!/bin/bash
set -eE -o functrace

failure() {
  local lineno=$1
  local msg=$2
  echo "Failed at $0 line $lineno: $msg"
}
trap 'failure $LINENO "$BASH_COMMAND"' ERR

DEFAULT_PROJECT_DIR="/home/$USERNAME/Documents/code"
PROJECT_DIR=${1:-$DEFAULT_PROJECT_DIR}

# Environment variables with defaults
REDIS_DATA_DIR=${REDIS_DATA_DIR:-"$PROJECT_DIR/.redis/data"}
REDIS_HOST_PORT=${REDIS_HOST_PORT:-6379}
REDIS_TAG=${REDIS_TAG:-latest}

# Check docker is installed
if ! command -v docker &> /dev/null; then
    echo "[$PROJECT_DIR] Docker is not installed. Please install Docker first."
    exit 1
fi

# Create redis data directory if it doesn't exist
if [ ! -d "$REDIS_DATA_DIR" ]; then
    mkdir -p "$REDIS_DATA_DIR"
    echo "[$PROJECT_DIR] Created Redis data directory at $REDIS_DATA_DIR"
fi

# Check if redis container already exists
if docker ps -a --format '{{.Names}}' | grep -q '^redis-container$'; then
    echo "[$PROJECT_DIR] Redis container already exists."
    # Check if it's running
    if docker ps --format '{{.Names}}' | grep -q '^redis-container$'; then
        echo "[$PROJECT_DIR] Redis container is already running."
    else
        echo "[$PROJECT_DIR] Starting existing Redis container..."
        docker start redis-container
    fi
else
    echo "[$PROJECT_DIR] Creating new Redis container..."
    docker run \
      --name redis-container \
      -v "$REDIS_DATA_DIR:/data" \
      -p ${REDIS_HOST_PORT}:6379 \
      -d redis:$REDIS_TAG \
      redis-server --save 60 1 --loglevel warning

    echo "[$PROJECT_DIR] Redis container created and started successfully."
    echo "[$PROJECT_DIR] Data will be persisted in: $REDIS_DATA_DIR"
    echo "[$PROJECT_DIR] Redis is accessible on port: $REDIS_HOST_PORT"
    echo "[$PROJECT_DIR] Using Redis version: $REDIS_TAG"
    echo "[$PROJECT_DIR] No authentication required (suitable for development)"
    echo "[$PROJECT_DIR] Connect with: redis-cli -h localhost -p $REDIS_HOST_PORT"
fi
