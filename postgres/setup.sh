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
POSTGRES_DB=${POSTGRES_DB:-default}
POSTGRES_DATA_DIR=${POSTGRES_DATA_DIR:-"$PROJECT_DIR/.postgres/$POSTGRES_DB"}
POSTGRES_HOST_PORT=${POSTGRES_HOST_PORT:-5432}
POSTGRES_TAG=${POSTGRES_TAG:-latest}
POSTGRES_PASSWORD=${POSTGRES_PASSWORD:-postgres}
POSTGRES_USER=${POSTGRES_USER:-postgres}

# Check docker is installed
if ! command -v docker &> /dev/null; then
    echo "[$PROJECT_DIR] Docker is not installed. Please install Docker first."
    exit 1
fi

# Create postgres data directory if it doesn't exist
if [ ! -d "$POSTGRES_DATA_DIR" ]; then
    mkdir -p "$POSTGRES_DATA_DIR"
    echo "[$PROJECT_DIR] Created PostgreSQL data directory at $POSTGRES_DATA_DIR"
fi

# Check if postgres container already exists
if docker ps -a --format '{{.Names}}' | grep -q '^postgres-default-container$'; then
    echo "[$PROJECT_DIR] PostgreSQL container already exists."
    # Check if it's running
    if docker ps --format '{{.Names}}' | grep -q '^postgres-default-container$'; then
        echo "[$PROJECT_DIR] PostgreSQL container is already running."
    else
        echo "[$PROJECT_DIR] Starting existing PostgreSQL container..."
        docker start postgres-default-container
    fi
else
    echo "[$PROJECT_DIR] Creating new PostgreSQL container..."
    docker run \
      --name postgres-default-container \
      -e POSTGRES_USER=${POSTGRES_USER} \
      -e POSTGRES_PASSWORD=${POSTGRES_PASSWORD} \
      -e POSTGRES_DB=${POSTGRES_DB} \
      -v "$POSTGRES_DATA_DIR:/var/lib/postgresql/data" \
      -p ${POSTGRES_HOST_PORT}:5432 \
      -d postgres:$POSTGRES_TAG

    echo "[$PROJECT_DIR] PostgreSQL container created and started successfully."
    echo "[$PROJECT_DIR] Data will be persisted in: $POSTGRES_DATA_DIR"
    echo "[$PROJECT_DIR] PostgreSQL is accessible on port: $POSTGRES_HOST_PORT"
    echo "[$PROJECT_DIR] Using PostgreSQL version: $POSTGRES_TAG"
    echo "[$PROJECT_DIR] Default credentials: user=${POSTGRES_USER}, password=${POSTGRES_PASSWORD}, database=${POSTGRES_DB}"
    echo "[$PROJECT_DIR] Connection string: postgresql://postgres:postgres@localhost:${POSTGRES_HOST_PORT}/${POSTGRES_DB}"
fi
