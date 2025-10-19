#!/usr/bin/env python3

import json
import subprocess
from pathlib import Path
import os

# --- Resolve user's home directory dynamically ---
home = Path(os.path.expanduser("~"))
settings_path = home / ".local/share/gt-ide/User/settings.json"

# --- Get full path to pwsh ---
try:
    pwsh_path = subprocess.check_output(["which", "pwsh"], text=True).strip()
except subprocess.CalledProcessError:
    raise SystemExit("❌ Error: 'pwsh' not found on PATH. Please install PowerShell first.")

# --- Load existing settings (if any) ---
if settings_path.exists():
    try:
        with settings_path.open("r", encoding="utf-8") as f:
            settings = json.load(f)
    except json.JSONDecodeError:
        print("Warning: settings.json is not valid JSON, starting fresh.")
        settings = {}
else:
    settings = {}

# --- Ensure nested dict and update values ---
additional_paths = settings.get("powershell.powerShellAdditionalExePaths", {})
additional_paths["PowerShell 7"] = pwsh_path

settings["powershell.powerShellDefaultVersion"] = "PowerShell 7"
settings["powershell.powerShellAdditionalExePaths"] = additional_paths

# --- Write updated settings ---
settings_path.parent.mkdir(parents=True, exist_ok=True)
with settings_path.open("w", encoding="utf-8") as f:
    json.dump(settings, f, indent=4)
    f.write("\n")

print(f"Updated PowerShell configuration for user '{home.name}'")
print(f"   → {settings_path}")
print(f"   Set 'PowerShell 7' to: {pwsh_path}")
