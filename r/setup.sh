#!/usr/bin/env python3
import os
import sys
import shlex
import subprocess
import threading
from pathlib import Path
from typing import Optional

SCRIPT_DIR = Path(__file__).resolve().parent
HOME_DIR = Path(os.environ.get("HOME") or f"/home/{os.environ.get('USERNAME','developer')}")

print(f"[info] SCRIPT_DIR={SCRIPT_DIR}")
print(f"[info] HOME_DIR={HOME_DIR}")

# =============================================================================
# Helpers
# =============================================================================
def run(cmd: str, *, check: bool = True, timeout: Optional[int] = 30) -> subprocess.CompletedProcess:
    """Run a shell command safely."""
    return subprocess.run(
        cmd if isinstance(cmd, list) else shlex.split(cmd),
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
        timeout=timeout,
        check=check,
    )

def read_os_release():
    distro = ""
    codename = ""
    version_id = ""
    # Try lsb_release first (may not exist in minimal images)
    try:
        out = run("lsb_release -si", check=True).stdout.strip().lower()
        if out:
            distro = out
        out = run("lsb_release -sc", check=True).stdout.strip()
        if out:
            codename = out
    except Exception:
        pass

    # Fallback /etc/os-release
    try:
        text = Path("/etc/os-release").read_text(encoding="utf-8")
        kv = {}
        for line in text.splitlines():
            if "=" in line:
                k, v = line.split("=", 1)
                kv[k.strip()] = v.strip().strip('"')
        distro = distro or kv.get("ID", "")
        codename = codename or kv.get("VERSION_CODENAME", "")
        version_id = kv.get("VERSION_ID", "")
    except Exception:
        pass

    return distro, codename, version_id

def choose_cran_url(distro: str, codename: str, version_id: str) -> str:
    cran = "https://cloud.r-project.org"
    if distro == "ubuntu":
        cran = f"https://packagemanager.posit.co/cran/__linux__/{codename or 'jammy'}/latest"
    elif distro == "debian":
        if not codename:
            if version_id.startswith("12"):
                codename = "bookworm"
            elif version_id.startswith("11"):
                codename = "bullseye"
            else:
                codename = "bookworm"
        cran = f"https://packagemanager.posit.co/cran/__linux__/{codename}/latest"
    return cran

def atomic_write(path: Path, data: str, mode: int = 0o644):
    tmp = path.with_suffix(path.suffix + ".tmp")
    tmp.write_text(data, encoding="utf-8")
    os.chmod(tmp, mode)
    tmp.replace(path)

def line_present(file: Path, needle: str) -> bool:
    try:
        return needle in file.read_text(encoding="utf-8").splitlines()
    except FileNotFoundError:
        return False

def append_line_if_missing(file: Path, line: str):
    file.parent.mkdir(parents=True, exist_ok=True)
    if not file.exists():
        file.write_text(line + "\n", encoding="utf-8")
        print(f"Added to {file}: {line}")
        return
    if not line_present(file, line):
        with file.open("a", encoding="utf-8") as f:
            f.write(line + "\n")
        print(f"Added to {file}: {line}")
    else:
        print(f"Already present in {file}: {line}")

# =============================================================================
# (A) Kernel install — background placeholder (do NOT wait)
# =============================================================================
def setup_jupyter_kernels():
    try:
        # TODO: add real kernel setup here
        pass
        print(f"[{SCRIPT_DIR}] Kernel installed successfully.")
    except Exception as e:
        print(f"[{SCRIPT_DIR}] Warning: Kernel packages failed to install: {e}")

kernel_thread = threading.Thread(target=setup_jupyter_kernels, daemon=True)
kernel_thread.start()  # do not join

# =============================================================================
# (B) .Rprofile — skip if exists; BSPM auto-on for Ubuntu
# =============================================================================
def setup_rprofile():
    template_path = SCRIPT_DIR / ".Rprofile.template"
    out_path = HOME_DIR / ".Rprofile"
    startup_pkgs = ' "tidyverse", "ggplot2", "dplyr", "readr", "tibble", "data.table", "rmarkdown", "knitr", "httpgd" '

    if out_path.exists():
        print(f".Rprofile already exists at {out_path} — skipping template render.")
        return

    if not template_path.exists():
        raise FileNotFoundError(f"Template not found at: {template_path}")

    distro, codename, version_id = read_os_release()
    cran_url = choose_cran_url(distro, codename, version_id)

    enable_bspm = (distro == "ubuntu")
    bspm_block = ""
    if enable_bspm:
        bspm_block = (
            'if (requireNamespace("bspm", quietly = TRUE)) {\n'
            '  try(bspm::enable(), silent = TRUE)\n'
            '}\n'
        )

    text = template_path.read_text(encoding="utf-8")
    text = text.replace("__CRAN_URL__", cran_url)
    text = text.replace("__BSPM_BLOCK__", bspm_block)
    text = text.replace("__STARTUP_PKGS__", startup_pkgs)

    atomic_write(out_path, text)
    print("Wrote:", out_path)
    print(f"  Distro: {distro or 'unknown'}  Codename: {codename or 'unknown'}")
    print(f"  CRAN:   {cran_url}")
    print(f"  bspm:   {'yes' if enable_bspm else 'no'}")
    print(f"  pkgs:   {startup_pkgs}")

# =============================================================================
# (C) Renviron + shell init (idempotent)
# =============================================================================
def setup_renviron_and_shell():
    renvi = HOME_DIR / ".Renviron"
    zshrc = HOME_DIR / ".zshrc"
    renvi.parent.mkdir(parents=True, exist_ok=True)
    zshrc.parent.mkdir(parents=True, exist_ok=True)
    renvi.touch(exist_ok=True)
    zshrc.touch(exist_ok=True)

    env_line = "R_LIBS_USER=~/.R/libs/%V"
    append_line_if_missing(renvi, env_line)

    init_line = 'mkdir -p ~/.R/libs/$(R -q --vanilla -e "cat(getRversion())" | tr -d "\\"")'
    append_line_if_missing(zshrc, init_line)

    # Try to create ~/.R/libs/<R-version>, ignoring startup files
    rver = ""
    base_env = os.environ.copy()
    base_env["R_PROFILE_USER"] = "/dev/null"
    base_env["R_ENVIRON_USER"] = "/dev/null"

    def try_get_ver(cmd):
        try:
            cp = subprocess.run(
                cmd, shell=True, text=True,
                stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                env=base_env, timeout=20, check=True
            )
            return cp.stdout.replace('"', "").strip()
        except Exception:
            return ""

    # Preferred probes
    rver = try_get_ver('R -q --vanilla -e "cat(getRversion())"')
    if not rver:
        rver = try_get_ver('Rscript --vanilla -e "cat(getRversion())"')

    if rver:
        lib_dir = HOME_DIR / ".R" / "libs" / rver
        lib_dir.mkdir(parents=True, exist_ok=True)
        print(f"Ensured user lib: {lib_dir}")
    else:
        # Last hint for debugging
        print("Could not determine R version. Skipping immediate user lib creation.")
        try:
            cp = subprocess.run("which R", shell=True, text=True,
                                stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=10)
            print("which R ->", cp.stdout.strip() or "(not found)")
        except Exception:
            pass


# Run (B) and (C) in parallel and wait (but we do not wait for the kernel thread)
threads = [
    threading.Thread(target=setup_rprofile, daemon=False),
    threading.Thread(target=setup_renviron_and_shell, daemon=False),
]
for t in threads:
    t.start()
for t in threads:
    t.join()

print("Done. Restart your shell or run: source ~/.zshrc")
