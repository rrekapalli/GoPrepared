#!/bin/bash
# Build GoPrepared deployment artifacts (Flutter PWA zip + Spring Boot jar).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
ARTIFACTS_DIR="${SCRIPT_DIR}/artifacts"
PROXMOX_DIR="${SCRIPT_DIR}/proxmox"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }

# shellcheck source=lib/resolve-flutter.sh
source "${SCRIPT_DIR}/lib/resolve-flutter.sh"
# shellcheck source=proxmox/lib/load-env.sh
source "${PROXMOX_DIR}/lib/load-env.sh" "$PROXMOX_DIR"

SKIP_PWA=false
SKIP_API=false
while [[ $# -gt 0 ]]; do
    case "$1" in
        --skip-pwa) SKIP_PWA=true; shift ;;
        --skip-api) SKIP_API=true; shift ;;
        --help|-h)
            echo "Usage: $0 [--skip-pwa] [--skip-api]"
            exit 0
            ;;
        *) log_error "Unknown option: $1"; exit 1 ;;
    esac
done

main() {
    load_goprepared_env "$PROXMOX_DIR"
    mkdir -p "$ARTIFACTS_DIR"

    if [[ "$SKIP_API" != true ]]; then
        build_api_artifact "$ROOT_DIR"
    fi

    if [[ "$SKIP_PWA" != true ]]; then
        log_info "Building GoPrepared PWA..."
        build_pwa_artifact_native "$ROOT_DIR" "$PWA_API_BASE_URL"
    fi

    log_info "Artifacts ready in ${ARTIFACTS_DIR}"
    ls -lh "$ARTIFACTS_DIR"
}

main
