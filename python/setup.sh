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

# If venv does not exist, create it
if [ ! -d "$PROJECT_DIR/.venv" ]; then
    uv venv "$PROJECT_DIR/.venv" --managed-python -p 3.12 --seed --no-project
    
    source "$PROJECT_DIR/.venv/bin/activate"
    
    uv pip install \
      black \
      isort \
      mypy \
      pylint \
      pytest \
      pytest-cov \
      ipython \
      ipykernel \
      jupyterlab \
      ipywidgets \
      bqplot \
      pythreejs \
      ipyleaflet \
      ipyvolume \
      nglview \
      mobilechelonian \
      rope

    echo "[$SCRIPT_DIR] Python virtual environment created and packages installed successfully."
else
    echo "[$SCRIPT_DIR] Python virtual environment already exists. Skipping creation."
fi
