#!/bin/bash
set -eE -o functrace

failure() {
  local lineno=$1
  local msg=$2
  echo "Failed at $0 line $lineno: $msg"
}
trap 'failure $LINENO "$BASH_COMMAND"' ERR

if [ -z "${USERNAME+x}" ]; then
  echo "Error: USERNAME is not set." >&2
  exit 1
fi

DEFAULT_PROJECT_ROOT="/home/$USERNAME/Documents/code"
PROJECT_DIR=${1:-$DEFAULT_PROJECT_ROOT}
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")

setupJupyterKernels(){
  USER_HOME="/home/$USERNAME"
  # 1) Install tslab if not already installed
  if [ ! -d "$USER_HOME/.local/node_modules/tslab" ]; then
    echo "→ Installing tslab locally..."
    npm install --prefix "$USER_HOME/.local" tslab
  else
    echo "✓ tslab already installed at $USER_HOME/.local/node_modules/tslab"
  fi
  
  # 2) Register the Jupyter kernel (if not yet registered)
  if ! jupyter kernelspec list 2>/dev/null | grep -q tslab; then
    echo "→ Registering tslab kernel with Jupyter..."
    "$USER_HOME/.local/node_modules/tslab/bin/tslab" install --python=python3 --binary="$USER_HOME/.local/bin/tslab"
  else
    echo "✓ tslab kernel already registered"
  fi
  
  # 3) Ensure ~/.local/bin exists
  if [ ! -d "$USER_HOME/.local/bin" ]; then
    echo "→ Creating $USER_HOME/.local/bin..."
    mkdir -p "$USER_HOME/.local/bin"
  fi
  
  # 4) Symlink tslab CLI into ~/.local/bin if missing or broken
  if [ ! -x "$USER_HOME/.local/bin/tslab" ]; then
    echo "→ Linking tslab binary into ~/.local/bin..."
    ln -sf "$USER_HOME/.local/node_modules/.bin/tslab" "$USER_HOME/.local/bin/tslab"
  else
    echo "✓ tslab link already exists: $USER_HOME/.local/bin/tslab"
  fi
  
  echo "✓ tslab installation complete!"
}

(
  setupJupyterKernels &&
  echo "[$SCRIPT_DIR] Kernel installed successfully." ||
  echo "[$SCRIPT_DIR] Warning: Kernel packages failed to install"
) &

# Create the project if it doesn't exist
if [ ! -f "$PROJECT_DIR/package.json" ]; then
    cp "$SCRIPT_DIR/project.json" "$PROJECT_DIR/package.json"

    cd $PROJECT_DIR
    npm install
    echo "[$SCRIPT_DIR] Javascript project initialized successfully."
else
    echo "[$SCRIPT_DIR] Javascript project already exists. Skipping initialization."
fi
