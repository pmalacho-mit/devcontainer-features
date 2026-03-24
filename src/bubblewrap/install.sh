#!/usr/bin/env bash
set -euo pipefail

# --- Install bubblewrap via the system package manager ---

install_via_apt() {
  apt-get update -y
  apt-get install -y --no-install-recommends bubblewrap
  # Clean up apt caches to keep the image slim
  rm -rf /var/lib/apt/lists/*
}

install_via_apk() {
  apk add --no-cache bubblewrap
}

install_via_dnf() {
  dnf install -y bubblewrap
  dnf clean all
}

if command -v apt-get >/dev/null 2>&1; then
  install_via_apt
elif command -v apk >/dev/null 2>&1; then
  install_via_apk
elif command -v dnf >/dev/null 2>&1; then
  install_via_dnf
else
  echo "ERROR: No supported package manager found (apt-get, apk, dnf)." >&2
  exit 1
fi

# --- Logs & sanity checks (non-fatal if they fail during build) ---
echo "bubblewrap installed via system package manager."

if command -v bwrap >/dev/null 2>&1; then
  echo "Detected on PATH: $(command -v bwrap)"
  bwrap --version || true
else
  echo "WARNING: bwrap not found on PATH after install."
fi
