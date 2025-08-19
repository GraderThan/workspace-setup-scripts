#!/bin/bash
set -eE -o functrace

failure() {
  local lineno=$1
  local msg=$2
  echo "Failed at $0 line $lineno: $msg"
}
trap 'failure $LINENO "$BASH_COMMAND"' ERR


# Check if first argument is provided
if [ $# -eq 0 ]; then
    echo "Error: Language argument is required"
    echo "Usage: $0 <language>"
    exit 1
fi

CODE_LANGUAGE=$1
PROJECT_ROOT=${PROJECT_ROOT:-"/home/$USERNAME/Documents/code"}
CACHE_DIR=${USER_CACHE_DIR:-"/home/$USERNAME/.gt-cache"}

# Get the directory of this script
TEMPLATE_DIR=$(dirname "$(readlink -f "$0")")

# convert CODE_LANGUAGE to lowercase
CODE_LANGUAGE=$(echo "$CODE_LANGUAGE" | tr '[:upper:]' '[:lower:]')

# Check if the language folder exists
LANGUAGE_DIR="$TEMPLATE_DIR/$CODE_LANGUAGE"
if [ ! -d "$LANGUAGE_DIR" ]; then
    echo "Error: Language '$CODE_LANGUAGE' not found"
    echo "Available languages:"
    for dir in "$TEMPLATE_DIR"/*/; do
        if [ -d "$dir" ] && [ -f "$dir/setup.sh" ]; then
            echo "  - $(basename "$dir")"
        fi
    done
    exit 1
fi

# Check if setup.sh exists in the language folder
if [ ! -f "$LANGUAGE_DIR/setup.sh" ]; then
    echo "Error: setup.sh not found in $CODE_LANGUAGE folder"
    exit 1
fi

# Run the language-specific setup script
echo "Setting up $CODE_LANGUAGE environment..."
chmod +x "$LANGUAGE_DIR/setup.sh"
bash "$LANGUAGE_DIR/setup.sh" "$PROJECT_ROOT" "$CACHE_DIR"
