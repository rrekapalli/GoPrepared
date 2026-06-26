#!/usr/bin/env bash
# Prepare Ubuntu 24.04 WSL for GoPrepared: build artifacts and deploy to Proxmox LXC.
#
# Usage (from repo root in WSL):
#   ./deployment/prepare-dev-machine.sh
#
# From Windows PowerShell:
#   powershell -File scripts/setup-wsl.ps1

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
# shellcheck source=lib/ensure-linux-bash.sh
source "${SCRIPT_DIR}/lib/ensure-linux-bash.sh"
ensure_linux_bash "$@"

log() { echo "[INFO] $*"; }

if [[ -f /etc/os-release ]]; then
    # shellcheck source=/dev/null
    source /etc/os-release
    log "WSL distro: ${PRETTY_NAME:-unknown}"
fi

if [[ "${ID:-}" != ubuntu ]] || [[ "${VERSION_ID:-}" != 24.04* ]]; then
    echo "[WARN] GoPrepared WSL setup is tested on Ubuntu 24.04. Current: ${PRETTY_NAME:-unknown}" >&2
fi

log "Repo: $REPO_ROOT"
bash "${SCRIPT_DIR}/install-wsl-dev-deps.sh"

echo ""
echo "=== GoPrepared WSL ready ==="
echo "  Java:     $(java -version 2>&1 | head -1)"
echo "  Maven:    $(command -v mvn >/dev/null && mvn -version 2>&1 | head -1 || echo missing)"
echo "  Deploy:   sshpass $(command -v sshpass >/dev/null && echo ok || echo missing), zip $(command -v zip >/dev/null && echo ok || echo missing)"
echo ""
echo "Next steps:"
echo "  cp .env.example .env    # edit secrets"
echo "  ./deploy.sh             # build + deploy to Proxmox LXC"
echo "  ./deploy.sh --skip-build"
echo ""
echo "Flutter PWA builds on Windows (PowerShell); deploy from WSL:"
echo "  powershell -File scripts/build_pwa_artifact.ps1"
echo "  ./deploy.sh --skip-build --ui-only"
echo ""
