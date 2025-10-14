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

setupJupyterKernels(){
  KPATH=$(echo /nix/store/*-xeus-cling-*/share/jupyter/kernels/xcpp17)
  jupyter kernelspec install "$KPATH" --user
}

(
  setupJupyterKernels &&
  echo "[$SCRIPT_DIR] Kernel installed successfully." ||
  echo "[$SCRIPT_DIR] Warning: Kernel packages failed to install"
) &

# Copy run-c and run-cpp to system bin
if [ ! -f /usr/local/bin/run-c ]; then
  sudo install -m 755 "$SCRIPT_DIR/run-c" /usr/local/bin/run-c

fi

if [ ! -f /usr/local/bin/run-cpp ]; then
  sudo install -m 755 "$SCRIPT_DIR/run-cpp" /usr/local/bin/run-cpp
fi
