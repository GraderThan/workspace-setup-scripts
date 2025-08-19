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
CACHE_DIR=${2:-"/home/$USERNAME/.gt-cache"}

setupJupyterKernels(){
  # Check if ijava-kernel.zip already exists in CACHE_DIR if not, download it
  if [ ! -f "$CACHE_DIR/ijava-kernel.zip" ]; then
    mkdir -p "$CACHE_DIR"
    cd "$CACHE_DIR"
    curl -s -L https://github.com/SpencerPark/IJava/releases/download/v1.3.0/ijava-1.3.0.zip -o ijava-kernel.zip
  fi

  # unzip the ijava-kernel.zip file to /etc/ijava-kernel
  cd /etc
  unzip -q "$CACHE_DIR/ijava-kernel.zip" -d ijava-kernel && cd ijava-kernel && python3 install.py --sys-prefix

  # make sure java kernel is listed as an installed kernel
  jupyter kernelspec list | grep -q 'java'
}

(
  setupJupyterKernels &&
  echo "[$SCRIPT_DIR] Kernel installed successfully." ||
  echo "[$SCRIPT_DIR] Warning: Kernel packages failed to install"
) &

