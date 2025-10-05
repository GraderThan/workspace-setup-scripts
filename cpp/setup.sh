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
  # Check if the environment exists
  if ! micromamba env list | grep -q '^xeus-cling\s'; then
    echo "Environment 'xeus-cling' not found. Creating it..."
    micromamba create -n xeus-cling --yes
  else
    echo "Environment 'xeus-cling' already exists."
  fi
  
  # Check if packages are installed in the environment
  if ! micromamba list -n xeus-cling | grep -q '^xeus-cling'; then
    echo "Installing xeus-cling and xwidgets..."
    micromamba install xeus-cling xwidgets -c conda-forge -n xeus-cling --yes
  else
    echo "Packages xeus-cling and xwidgets already installed."
  fi
  
  # Check if the Jupyter kernel is already installed
  KERNEL_DIR="$HOME/.local/share/jupyter/kernels/xcpp17"
  if [ ! -d "$KERNEL_DIR" ]; then
    echo "Installing Jupyter kernel for xeus-cling..."
    jupyter kernelspec install /home/developer/micromamba/envs/xeus-cling/share/jupyter/kernels/xcpp17 --user
  else
    echo "Jupyter kernel already installed."
  fi
}

(
  setupJupyterKernels &&
  echo "[$SCRIPT_DIR] Kernel installed successfully." ||
  echo "[$SCRIPT_DIR] Warning: Kernel packages failed to install"
) &

# if the project dir is empty initialize it
if [ -z "$(ls -A $PROJECT_ROOT)" ]; then
  mkdir -p $PROJECT_ROOT/src
  mkdir -p $PROJECT_ROOT/build
  mkdir -p $PROJECT_ROOT/lib
  mkdir -p $PROJECT_ROOT/include
  mkdir -p $PROJECT_ROOT/test
fi

# Copy run-c and run-cpp to system bin
if [ ! -f /usr/local/bin/run-c ]; then
  cp "$SCRIPT_DIR/run-c" /usr/local/bin/run-c
  chmod +x /usr/local/bin/run-c
fi

if [ ! -f /usr/local/bin/run-cpp ]; then
  cp "$SCRIPT_DIR/run-cpp" /usr/local/bin/run-cpp
  chmod +x /usr/local/bin/run-cpp
fi
