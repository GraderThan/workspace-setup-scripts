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

installGlobalPackages() {
    # Install global Python packages
    pip install \
      bqplot \
      pythreejs \
      ipyleaflet \
      ipyvolume \
      nglview \
      mobilechelonian \
      pre-commit
}

(
  installGlobalPackages &&
  echo "[$SCRIPT_DIR] Global Python packages installed successfully." ||
  echo "[$SCRIPT_DIR] Warning: Some optional global packages failed to install"
) &

# If venv does not exist, create it
if [ ! -d "$PROJECT_DIR/.venv" ]; then
    python3 -m venv "$PROJECT_DIR/.venv"

    $PROJECT_DIR/.venv/bin/pip install --upgrade \
      pip \
      setuptools \
      wheel

    $PROJECT_DIR/.venv/bin/pip install \
      black \
      isort \
      mypy \
      pylint \
      pytest \
      pytest-cov \
      ipython \
      ipykernel \
      jupyterlab \
      rope

    echo "[$SCRIPT_DIR] Python virtual environment created and packages installed successfully."
else
    echo "[$SCRIPT_DIR] Python virtual environment already exists. Skipping creation."
fi
