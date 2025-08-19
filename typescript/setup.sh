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
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")

setupJupyterKernels(){
    # Installs javascript jupyter kernel
    npm install -g tslab
    tslab install --python=python3

    # Remove the javascript kernel
    rm -rf /usr/local/share/jupyter/kernels/jslab
}

(
  setupJupyterKernels &&
  echo "[$SCRIPT_DIR] Kernel installed successfully." ||
  echo "[$SCRIPT_DIR] Warning: Kernel packages failed to install"
) &

# Create the project if it doesn't exist
if [ ! -f "$PROJECT_DIR/package.json" ]; then
    cp "$SCRIPT_DIR/project.json" "$PROJECT_DIR/package.json"
    cp "$SCRIPT_DIR/tsconfig.json" "$PROJECT_DIR/tsconfig.json"

    cd $PROJECT_DIR
    npm install
    echo "[$SCRIPT_DIR] TypeScript project initialized successfully."
else
    echo "[$SCRIPT_DIR] TypeScript project already exists. Skipping initialization."
fi
