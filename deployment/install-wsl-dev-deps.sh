#!/usr/bin/env bash
# Install WSL dev prerequisites for GoPrepared (deploy + content + API build).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=== GoPrepared WSL dev dependencies ==="
bash "${SCRIPT_DIR}/install-java-maven.sh"

log() { echo "[INFO] $*"; }

log "Installing deploy tools (git, zip, unzip, curl, sshpass, jq, python3-venv, dos2unix)..."
missing=()
for pkg in git zip unzip curl sshpass jq python3-venv dos2unix; do
    dpkg -s "$pkg" >/dev/null 2>&1 || missing+=("$pkg")
done
if ((${#missing[@]} > 0)); then
    sudo apt-get update -qq
    sudo apt-get install -y "${missing[@]}"
else
    log "Deploy tools already installed."
fi

log "Normalizing shell script line endings (CRLF → LF)..."
find "${SCRIPT_DIR}/.." -name '*.sh' -type f -exec dos2unix -q {} + 2>/dev/null || true
find "${SCRIPT_DIR}/.." -maxdepth 1 -name '*.sh' -exec chmod +x {} + 2>/dev/null || true
chmod +x "${SCRIPT_DIR}"/*.sh "${SCRIPT_DIR}"/proxmox/*.sh "${SCRIPT_DIR}"/proxmox/lib/*.sh "${SCRIPT_DIR}"/proxmox/scripts/*.sh 2>/dev/null || true
find "${SCRIPT_DIR}/../scripts" -maxdepth 1 -name '*.sh' -exec chmod +x {} + 2>/dev/null || true

touch "$HOME/.goprepared-wsl-setup"
echo "=== Done. Open a new terminal or: source ~/.bashrc ==="
