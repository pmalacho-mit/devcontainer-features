#!/usr/bin/env bash
set -euo pipefail

# --- Configurable via feature options or env ---
REPO_URL="${REPO_URL:-https://github.com/ingydotnet/git-subrepo.git}"
INSTALL_DIR="${INSTALL_DIR:-/usr/local/share/git-subrepo}"
TARGET_BIN_DIR="${TARGET_BIN_DIR:-/usr/local/bin}"

# Who is the default non-root user to patch (if needed)?
USERNAME="${USERNAME:-automatic}"

# --- Helper: detect a reasonable non-root user if 'automatic' ---
detect_user() {
  local user
  if [ "$USERNAME" = "automatic" ]; then
    for user in vscode node codespace "$(awk -F: '$3==1000{print $1}' /etc/passwd)"; do
      if id -u "$user" >/dev/null 2>&1; then
        USERNAME="$user"
        break
      fi
    done
    # Fall back to root if nothing else found
    if [ "$USERNAME" = "automatic" ]; then
      USERNAME="root"
    fi
  fi
}
detect_user

# --- Clone / update repo into a system-wide location ---
if [ ! -d "${INSTALL_DIR}/.git" ]; then
  mkdir -p "$(dirname "$INSTALL_DIR")"
  git clone --depth 1 "$REPO_URL" "$INSTALL_DIR"
else
  git -C "$INSTALL_DIR" fetch --tags origin
  # Use ff-only to avoid accidental local changes breaking the feature
  git -C "$INSTALL_DIR" pull --ff-only
fi

# Make sure everyone can read/execute the files
chmod -R a+rX "$INSTALL_DIR"

# --- Ensure the executable is on PATH even if .rc isn’t sourced ---
if [ -f "${INSTALL_DIR}/lib/git-subrepo" ]; then
  mkdir -p "$TARGET_BIN_DIR"
  ln -sf "${INSTALL_DIR}/lib/git-subrepo" "${TARGET_BIN_DIR}/git-subrepo"
fi

# --- Wire up shell init so aliases/completions in .rc load automatically ---
RC_LINE="source \"${INSTALL_DIR}/.rc\"  # devcontainer-feature: git-subrepo"

append_once() {
  local file="$1"
  local line="$2"
  # Some base images may not ship these files; create them if missing.
  touch "$file"
  # Only append if not already present
  if ! grep -Fq "$line" "$file"; then
    printf '\n%s\n' "$line" >> "$file"
  fi
}

# Global bash and zsh (covers most interactive shells in devcontainers)
if [ -f /etc/bash.bashrc ]; then
  append_once /etc/bash.bashrc "$RC_LINE"
fi
if [ -f /etc/zsh/zshrc ]; then
  append_once /etc/zsh/zshrc "$RC_LINE"
fi

# As a fallback, also patch the target user's dotfiles (useful if the image ignores the global rc)
user_home="$(getent passwd "$USERNAME" | cut -d: -f6 || true)"
if [ -n "${user_home:-}" ] && [ -d "$user_home" ]; then
  if [ -w "$user_home" ]; then
    # bash
    append_once "${user_home}/.bashrc" "$RC_LINE"
    # zsh
    append_once "${user_home}/.zshrc" "$RC_LINE"
    # Ensure the user owns the files (when run as root)
    chown "$USERNAME":"$USERNAME" "${user_home}/.bashrc" "${user_home}/.zshrc" 2>/dev/null || true
  fi
fi

echo "git-subrepo installed to: $INSTALL_DIR"
echo "git-subrepo symlinked at: ${TARGET_BIN_DIR}/git-subrepo"
echo "Shell init updated to source: ${INSTALL_DIR}/.rc"
