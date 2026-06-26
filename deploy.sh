#!/bin/bash
# Build and deploy GoPrepared to Proxmox LXC (VMID 7003).
#
# Usage:
#   ./deploy.sh                  # build + deploy API + PWA
#   ./deploy.sh --skip-build     # deploy existing artifacts only
#   ./deploy.sh --recreate       # recreate LXC before deploy
#   ./deploy.sh --ui-only        # PWA only
#   ./deploy.sh --api-only       # API only

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=deployment/lib/ensure-linux-bash.sh
source "${ROOT_DIR}/deployment/lib/ensure-linux-bash.sh"
ensure_linux_bash "$@"

DEPLOYMENT_DIR="${ROOT_DIR}/deployment"
PROXMOX_DIR="${DEPLOYMENT_DIR}/proxmox"
ARTIFACTS_DIR="${DEPLOYMENT_DIR}/artifacts"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

RECREATE=false
SKIP_BUILD=false
UI_ONLY=false
API_ONLY=false

show_help() {
    cat <<'EOF'
Usage: ./deploy.sh [OPTIONS]

Build artifacts and deploy GoPrepared to Proxmox LXC (nginx PWA + Spring Boot API).

OPTIONS:
  --recreate       Destroy and recreate the LXC before deploy
  --skip-build     Deploy using existing deployment/artifacts/
  --ui-only        Deploy PWA only (requires pwa-dist.zip)
  --api-only       Deploy API only (requires go-prepared-api.jar)
  --help, -h       Show this help

Examples:
  ./deploy.sh
  ./deploy.sh --skip-build
  ./deploy.sh --recreate
  ./deployment/proxmox/diagnose.sh
EOF
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --recreate) RECREATE=true; shift ;;
        --skip-build) SKIP_BUILD=true; shift ;;
        --ui-only) UI_ONLY=true; shift ;;
        --api-only) API_ONLY=true; shift ;;
        --help|-h) show_help; exit 0 ;;
        *) log_error "Unknown option: $1"; show_help; exit 1 ;;
    esac
done

if [[ "$UI_ONLY" == true && "$API_ONLY" == true ]]; then
    log_error "Choose --ui-only or --api-only, not both"
    exit 1
fi

log_info "GoPrepared deploy | Recreate: $RECREATE | Skip build: $SKIP_BUILD"

if [[ "$SKIP_BUILD" != true ]]; then
    PREPARE_FLAGS=()
    [[ "$UI_ONLY" == true ]] && PREPARE_FLAGS+=(--skip-api)
    [[ "$API_ONLY" == true ]] && PREPARE_FLAGS+=(--skip-pwa)
    "${DEPLOYMENT_DIR}/prepare-artifacts.sh" "${PREPARE_FLAGS[@]}"
fi

RECREATE_FLAG=""
[[ "$RECREATE" == true ]] && RECREATE_FLAG="--recreate"

if [[ "$UI_ONLY" == true ]]; then
    [[ -f "${ARTIFACTS_DIR}/pwa-dist.zip" ]] || { log_error "Missing pwa-dist.zip"; exit 1; }
    "${PROXMOX_DIR}/deploy-ui.sh" $RECREATE_FLAG
elif [[ "$API_ONLY" == true ]]; then
    [[ -f "${ARTIFACTS_DIR}/go-prepared-api.jar" ]] || { log_error "Missing go-prepared-api.jar"; exit 1; }
    "${PROXMOX_DIR}/deploy-api.sh" $RECREATE_FLAG
else
    [[ -f "${ARTIFACTS_DIR}/pwa-dist.zip" ]] || { log_error "Missing pwa-dist.zip"; exit 1; }
    [[ -f "${ARTIFACTS_DIR}/go-prepared-api.jar" ]] || { log_error "Missing go-prepared-api.jar"; exit 1; }
    "${PROXMOX_DIR}/deploy-lxc.sh" $RECREATE_FLAG
fi

log_success "Deployment finished"
