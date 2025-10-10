#!/usr/bin/env python3
import os
import shlex
import shutil
import subprocess
import threading
from pathlib import Path
from typing import Optional

SCRIPT_DIR = Path(__file__).resolve().parent
HOME_DIR = Path(os.environ.get("HOME")
                or f"/home/{os.environ.get('USERNAME','developer')}")

print(f"[info] SCRIPT_DIR={SCRIPT_DIR}")
print(f"[info] HOME_DIR={HOME_DIR}")

# =============================================================================
# Helpers
# =============================================================================


def run(cmd: str, *, check: bool = True, timeout: Optional[int] = 30) -> subprocess.CompletedProcess:
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
    try:
        out = run("lsb_release -si", check=True).stdout.strip().lower()
        if out:
            distro = out
        out = run("lsb_release -sc", check=True).stdout.strip()
        if out:
            codename = out
    except Exception:
        pass
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
            if (version_id or "").startswith("12"):
                codename = "bookworm"
            elif (version_id or "").startswith("11"):
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
        return needle.strip() in [l.strip() for l in file.read_text(encoding="utf-8").splitlines()]
    except FileNotFoundError:
        return False


def append_line_if_missing(file: Path, line: str):
    file.parent.mkdir(parents=True, exist_ok=True
                      )
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

    # Ensure file ends with newline
    content = file.read_text(encoding="utf-8")
    if content and not content.endswith("\n"):
        file.write_text(content + "\n", encoding="utf-8")


def apt_available() -> bool:
    # Consider apt present if either apt-get or apt is on PATH
    return bool(shutil.which("apt-get") or shutil.which("apt"))

# =============================================================================
# (A) Kernel install — background placeholder (do NOT wait)
# =============================================================================


def setup_jupyter_kernels():
    try:
        run("R -q -e 'IRkernel::installspec(user=TRUE)'", check=True, timeout=120)
        print(f"[{SCRIPT_DIR}] Kernel packages successfully installed")
    except Exception as e:
        print(f"[{SCRIPT_DIR}] Warning: Kernel packages failed to install: {e}")

# =============================================================================
# (B) .Rprofile — skip if exists; BSPM on only if apt present
# =============================================================================


def setup_rprofile():
    template_path = SCRIPT_DIR / ".Rprofile.template"
    out_path = HOME_DIR / ".Rprofile"
    startup_pkgs = ' "tidyverse", "ggplot2", "dplyr", "readr", "tibble", "rmarkdown", "knitr", "httpgd" '

    if out_path.exists():
        print(
            f".Rprofile already exists at {out_path} — skipping template render.")
        return

    if not template_path.exists():
        raise FileNotFoundError(f"Template not found at: {template_path}")

    distro, codename, version_id = read_os_release()
    cran_url = choose_cran_url(distro, codename, version_id)

    bspm_block = ""
    if apt_available():
        # Always-on *if* apt is available; guarded by requireNamespace/try
        bspm_block = (
            'options(\n'
            '  bspm.sudo = TRUE,\n'
            '  bspm.version.check = FALSE,\n'
            '  bspm.fallback = TRUE\n'
            ')\n'
            'if (requireNamespace("bspm", quietly = TRUE)) {\n'
            '  try(bspm::enable(), silent = TRUE)\n'
            '}\n'
        )

    text = template_path.read_text(encoding="utf-8")
    text = text.replace("__CRAN_URL__", cran_url)
    text = text.replace("__BSPM_BLOCK__", bspm_block)
    text = text.replace("__STARTUP_PKGS__", startup_pkgs)

    if not text.endswith("\n"):
        text += "\n"
    atomic_write(out_path, text)
    print("Wrote:", out_path)
    print(
        f"  Distro: {distro or 'unknown'}  Codename: {codename or 'unknown'}")
    print(f"  CRAN:   {cran_url}")
    print(
        f"  bspm:   {'enabled (apt detected)' if bspm_block else 'skipped (no apt)'}")
    print(f"  pkgs:   {startup_pkgs}")

# =============================================================================
# (C) Renviron + user lib (quiet; no zsh edits that print)
# =============================================================================


def setup_renviron_and_userlib():
    renvi = HOME_DIR / ".Renviron"
    renvi.parent.mkdir(parents=True, exist_ok=True)

    # Ensure R_LIBS_USER is set
    env_line = f"R_LIBS_USER={HOME_DIR}/.R/libs/%V"
    append_line_if_missing(renvi, env_line)

    env_line = f"R_PROFILE_USER={HOME_DIR}/.Rprofile"
    append_line_if_missing(renvi, env_line)

    # Create ~/.R/libs/%V now (quiet, no console output in zsh)
    rver = ""
    try:
        cp = run('R --vanilla -s -e "cat(as.character(getRversion()))"', check=True)
        rver = cp.stdout.strip()
    except Exception as e:
        print(
            f"Could not determine R version. Skipping immediate user lib creation. ({e})")

    if rver:
        libdir = HOME_DIR / ".R" / "libs" / rver
        libdir.mkdir(parents=True, exist_ok=True)
        print(f"Ensured user lib: {libdir}")


# Run (B) and (C) in parallel and wait (kernel thread remains background)
threads = [
    threading.Thread(target=setup_rprofile, daemon=False),
    threading.Thread(target=setup_renviron_and_userlib, daemon=False),
]
for t in threads:
    t.start()
for t in threads:
    t.join()

kernel_thread = threading.Thread(target=setup_jupyter_kernels, daemon=True)
kernel_thread.start() 

print("Done. Restart your shell or run: source ~/.zshrc")
