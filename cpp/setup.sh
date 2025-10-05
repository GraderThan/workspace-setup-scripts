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
  #!/usr/bin/env bash
  set -euo pipefail
  
  ENV_NAME="xeus-cling"
  CHANNEL="-c conda-forge"
  
  # Packages xeus-cling needs to find the STL and run well on Linux
  PKGS=(
    xeus-cling
    xwidgets
    jupyterlab
    gxx_linux-64
    gcc_linux-64
    libstdcxx-devel_linux-64
    libgcc-devel_linux-64
    sysroot_linux-64
  )
  
  # 1) Create the env with all packages if it doesn't exist
  if ! micromamba env list | awk '{print $1}' | grep -qx "${ENV_NAME}"; then
    echo "Environment '${ENV_NAME}' not found. Creating it with required packages..."
    micromamba create -n "${ENV_NAME}" ${CHANNEL} "${PKGS[@]}" --yes
  else
    echo "Environment '${ENV_NAME}' already exists. Ensuring required packages are present..."
    micromamba install -n "${ENV_NAME}" ${CHANNEL} "${PKGS[@]}" --yes
  fi
  
  # 2) Sanity check: xcpp and the compiler should be available in the env
  echo "Sanity checks..."
  micromamba run -n "${ENV_NAME}" xcpp --version >/dev/null
  micromamba run -n "${ENV_NAME}" x86_64-conda-linux-gnu-c++ --version >/dev/null
  echo "xcpp and compiler detected."
  
  # 3) Install (or refresh) the Jupyter kernelspec from inside the env
  #    This ensures the argv points to .../envs/${ENV_NAME}/bin/xcpp
  if micromamba run -n "${ENV_NAME}" jupyter kernelspec list | grep -q '^xcpp17 '; then
    echo "Jupyter kernel xcpp17 already registered. Refreshing to be safe..."
    micromamba run -n "${ENV_NAME}" jupyter kernelspec remove -y xcpp17 || true
  fi
  
  echo "Installing Jupyter kernel for xeus-cling..."
  micromamba run -n "${ENV_NAME}" bash -lc 'jupyter kernelspec install --user "$CONDA_PREFIX/share/jupyter/kernels/xcpp17"'
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
