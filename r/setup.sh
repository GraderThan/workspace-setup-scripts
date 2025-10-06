#!/usr/bin/env bash
set -eEuo pipefail

failure() {
  local lineno=$1 msg=$2
  echo "Failed at $0 line $lineno: $msg" >&2
}
trap 'failure $LINENO "$BASH_COMMAND"' ERR

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
HOME_DIR="${HOME:-/home/${USERNAME:-developer}}"

echo "[info] SCRIPT_DIR=$SCRIPT_DIR"
echo "[info] HOME_DIR=$HOME_DIR"

# =============================================================================
# (A) Jupyter Kernels — run in background and DO NOT wait
# =============================================================================
setupJupyterKernels() {
  # placeholder; add your kernel installs here
  :
}

(
  setupJupyterKernels &&
  echo "[$SCRIPT_DIR] Kernel installed successfully." ||
  echo "[$SCRIPT_DIR] Warning: Kernel packages failed to install"
) &

# =============================================================================
# (B) .Rprofile — run in background, SKIP if exists
# =============================================================================
setup_rprofile() {
  local TEMPLATE_PATH="$SCRIPT_DIR/.Rprofile.template"
  local OUT_PATH="$HOME_DIR/.Rprofile"
  local ENABLE_BSPM="yes"
  local STARTUP_PKGS=' "tidyverse", "ggplot2", "dplyr", "readr", "tibble", "data_table", "rmarkdown", "knitr", "httpgd" '

  if [[ -f "$OUT_PATH" ]]; then
    echo ".Rprofile already exists at $OUT_PATH — skipping template render."
    return 0
  fi

  if [[ ! -f "$TEMPLATE_PATH" ]]; then
    echo "Template not found at: $TEMPLATE_PATH" >&2
    return 1
  fi

  local DISTRO="" CODENAME="" VERSION_ID=""
  if command -v lsb_release >/dev/null 2>&1; then
    DISTRO="$(lsb_release -si 2>/dev/null | tr '[:upper:]' '[:lower:]' || true)"
    CODENAME="$(lsb_release -sc 2>/dev/null || true)"
  fi
  if [[ -r /etc/os-release ]]; then
    . /etc/os-release
    DISTRO="${DISTRO:-$ID}"
    CODENAME="${CODENAME:-${VERSION_CODENAME:-}}"
    VERSION_ID="${VERSION_ID:-${VERSION_ID:-}}"
  fi

  local CRAN_URL="https://cloud.r-project.org"
  case "$DISTRO" in
    ubuntu)
      CRAN_URL="https://packagemanager.posit.co/cran/__linux__/${CODENAME:-jammy}/latest"
      ;;
    debian)
      if [[ -z "$CODENAME" ]]; then
        case "$VERSION_ID" in
          12*) CODENAME="bookworm" ;;
          11*) CODENAME="bullseye" ;;
          *)   CODENAME="bookworm" ;;
        esac
      fi
      CRAN_URL="https://packagemanager.posit.co/cran/__linux__/${CODENAME}/latest"
      ;;
  esac

  local BSPM_BLOCK=""
  if [[ "$ENABLE_BSPM" == "yes" ]]; then
    read -r -d '' BSPM_BLOCK <<'EOF' || true
if (requireNamespace("bspm", quietly = TRUE)) {
  try(bspm::enable(), silent = TRUE)
}
EOF
  fi

  python3 - "$TEMPLATE_PATH" "$OUT_PATH" \
    "$(printf '%s' "$CRAN_URL")" \
    "$(printf '%s' "$BSPM_BLOCK")" \
    "$(printf '%s' "$STARTUP_PKGS")" <<'PY'
import sys, pathlib
tpl_path = pathlib.Path(sys.argv[1])
out_path = pathlib.Path(sys.argv[2])
cran_url = sys.argv[3]
bspm_block = sys.argv[4]
startup_pkgs = sys.argv[5]
text = tpl_path.read_text(encoding="utf-8")
text = text.replace("__CRAN_URL__", cran_url)
text = text.replace("__BSPM_BLOCK__", bspm_block)
text = text.replace("__STARTUP_PKGS__", startup_pkgs)
out_path.write_text(text, encoding="utf-8")
PY

  echo "Wrote: $OUT_PATH"
  echo "  Distro: ${DISTRO:-unknown}  Codename: ${CODENAME:-unknown}"
  echo "  CRAN:   $CRAN_URL"
  echo "  bspm:   $ENABLE_BSPM"
  echo "  pkgs:   $STARTUP_PKGS"
}

# =============================================================================
# (C) Renviron setup — run in background
# =============================================================================
setup_renviron_and_shell() {
  local RENVI="$HOME_DIR/.Renviron"
  local ZSHRC="$HOME_DIR/.zshrc"

  [[ -f "$RENVI" ]] || touch "$RENVI"
  [[ -f "$ZSHRC" ]] || touch "$ZSHRC"

  local ENV_LINE='R_LIBS_USER=~/.R/libs/%V'
  if ! grep -Fqx "$ENV_LINE" "$RENVI"; then
    echo "$ENV_LINE" >> "$RENVI"
    echo "Added R_LIBS_USER to $RENVI"
  else
    echo "R_LIBS_USER already present in $RENVI"
  fi

  local INIT_LINE='mkdir -p ~/.R/libs/$(R -q -e "cat(getRversion())" | tr -d "\"")'
  if ! grep -Fqx "$INIT_LINE" "$ZSHRC"; then
    echo "$INIT_LINE" >> "$ZSHRC"
    echo "Added mkdir initialization to $ZSHRC"
  else
    echo "mkdir initialization already present in $ZSHRC"
  fi

  if command -v R >/dev/null 2>&1; then
    local RVER
    RVER="$(R -q -e 'cat(getRversion())' | tr -d '"')"
    mkdir -p "$HOME_DIR/.R/libs/$RVER"
    echo "Ensured user lib: $HOME_DIR/.R/libs/$RVER"
  else
    echo "R not found on PATH; skipping immediate dir creation."
  fi
}

# ------------------------- run B & C in parallel -------------------------
pids=()

setup_rprofile &   pids+=($!)
setup_renviron_and_shell & pids+=($!)

for pid in "${pids[@]}"; do
  if ! wait "$pid"; then
    echo "A setup task (PID $pid) failed." >&2
    exit 1
  fi
done

echo "Done. Restart your shell or run: source ~/.zshrc"
