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

export GOPATH="/home/$USERNAME/go"
export GOTOOLCHAIN=auto

go install honnef.co/go/tools/cmd/staticcheck@latest &

