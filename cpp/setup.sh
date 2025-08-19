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
  conda update -y conda
  conda create -n xeus-cling --yes
  conda install xeus-cling xwidgets -c conda-forge -n xeus-cling --yes
  jupyter kernelspec install /etc/miniconda/envs/xeus-cling/share/jupyter/kernels/xcpp17 --sys-prefix
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
