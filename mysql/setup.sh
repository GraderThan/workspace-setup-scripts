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
MYSQL_DATABASE=${MYSQL_DATABASE:-default}
MYSQL_DATA_DIR=${MYSQL_DATA_DIR:-"$PROJECT_DIR/.mysql/$MYSQL_DATABASE"}
MYSQL_HOST_PORT=${MYSQL_HOST_PORT:-3306}
MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD:-mysql}
MYSQL_TAG=${MYSQL_TAG:-latest}

# Check docker is installed
if ! command -v docker &> /dev/null; then
    echo "[$PROJECT_DIR] Docker is not installed. Please install Docker first."
    exit 1
fi

# Create mysql data directory if it doesn't exist
if [ ! -d "$MYSQL_DATA_DIR" ]; then
    mkdir -p "$MYSQL_DATA_DIR"
    echo "[$PROJECT_DIR] Created MySQL data directory at $MYSQL_DATA_DIR"
fi

# Check if mysql container already exists
if docker ps -a --format '{{.Names}}' | grep -q '^mysql-default-container$'; then
    echo "[$PROJECT_DIR] MySQL container already exists."
    # Check if it's running
    if docker ps --format '{{.Names}}' | grep -q '^mysql-default-container$'; then
        echo "[$PROJECT_DIR] MySQL container is already running."
    else
        echo "[$PROJECT_DIR] Starting existing MySQL container..."
        docker start mysql-default-container
    fi
else
    echo "[$PROJECT_DIR] Creating new MySQL container..."
    docker run \
      --name mysql-default-container \
      -e MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD} \
      -e MYSQL_DATABASE=${MYSQL_DATABASE} \
      -v "$MYSQL_DATA_DIR:/var/lib/mysql" \
      -p ${MYSQL_HOST_PORT}:3306 \
      -d mysql:$MYSQL_TAG

    echo "[$PROJECT_DIR] MySQL container created and started successfully."
    echo "[$PROJECT_DIR] Data will be persisted in: $MYSQL_DATA_DIR"
    echo "[$PROJECT_DIR] MySQL is accessible on port: $MYSQL_HOST_PORT"
    echo "[$PROJECT_DIR] Using MySQL version: $MYSQL_TAG"
    echo "[$PROJECT_DIR] Default credentials: user=root, password=${MYSQL_ROOT_PASSWORD}, database=${MYSQL_DATABASE}"
    echo "[$PROJECT_DIR] Connection string: mysql://root:${MYSQL_ROOT_PASSWORD}@localhost:${MYSQL_HOST_PORT}/${MYSQL_DATABASE}"
    echo "[$PROJECT_DIR] Connect with: mysql -u root -p ${MYSQL_ROOT_PASSWORD} -h localhost -P ${MYSQL_HOST_PORT} ${MYSQL_DATABASE}"
fi
