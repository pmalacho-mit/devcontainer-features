#!/usr/bin/env bash
set -euo pipefail

# --- Configurable via feature options or env ---
REPO_URL="${REPO_URL:-https://github.com/ingydotnet/git-subrepo.git}"
INSTALL_DIR="${INSTALL_DIR:-/usr/local/share/git-subrepo}"
TARGET_BIN_DIR="${TARGET_BIN_DIR:-/usr/local/bin}"

# --- Clone / update repo into a system-wide location ---
if [ ! -d "${INSTALL_DIR}/.git" ]; then
  mkdir -p "${INSTALL_DIR}"
  git clone --depth 1 "$REPO_URL" "$INSTALL_DIR"
else
  git -C "$INSTALL_DIR" fetch --tags origin
  git -C "$INSTALL_DIR" pull --ff-only
fi

# Ensure readable + executable main script (location per upstream)
if [ -f "${INSTALL_DIR}/lib/git-subrepo" ]; then
  chmod a+rx "${INSTALL_DIR}/lib/git-subrepo"
fi

# --- Provide a stable shim on PATH (works for `git-subrepo` AND `git subrepo`) ---
mkdir -p "$TARGET_BIN_DIR"
cat > "${TARGET_BIN_DIR}/git-subrepo" <<'SHIM'
#!/usr/bin/env bash
set -euo pipefail
ROOT="${GIT_SUBREPO_ROOT:-/usr/local/share/git-subrepo}"
exec "${ROOT}/lib/git-subrepo" "$@"
SHIM
chmod 0755 "${TARGET_BIN_DIR}/git-subrepo"

# --- Optional: source .rc for completions & MANPATH across login shells ---
cat > /etc/profile.d/git-subrepo.sh <<EOF
# devcontainer-feature: git-subrepo
export GIT_SUBREPO_ROOT="${INSTALL_DIR}"
[ -f "\$GIT_SUBREPO_ROOT/.rc" ] && . "\$GIT_SUBREPO_ROOT/.rc"
EOF
chmod 0644 /etc/profile.d/git-subrepo.sh

# --- Logs & sanity checks (non-fatal if they fail during build) ---
echo "git-subrepo installed at: ${INSTALL_DIR}"
echo "shim installed at: ${TARGET_BIN_DIR}/git-subrepo"

if command -v git-subrepo >/dev/null 2>&1; then
  echo "Detected on PATH: $(command -v git-subrepo)"
else
  echo "WARNING: git-subrepo not on PATH during build; it should be available in interactive shells."
fi

# Prove the 'git subrepo' entrypoint if possible
if git subrepo --version >/dev/null 2>&1; then
  git subrepo --version
fi
