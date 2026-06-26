#!/bin/bash
# Full GoPrepared LXC deploy: API + PWA (nginx reverse proxy).
# Usage: ./deploy-lxc.sh [--recreate] [--skip-ui] [--skip-api]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/deploy-logging.sh
source "${SCRIPT_DIR}/scripts/deploy-logging.sh"
# shellcheck source=lib/load-env.sh
source "${SCRIPT_DIR}/lib/load-env.sh" "$SCRIPT_DIR"
# shellcheck source=lib/proxmox-remote.sh
source "${SCRIPT_DIR}/lib/proxmox-remote.sh"

RECREATE=false
SKIP_UI=false
SKIP_API=false
while [[ $# -gt 0 ]]; do
    case "$1" in
        --recreate) RECREATE=true; shift ;;
        --skip-ui) SKIP_UI=true; shift ;;
        --skip-api) SKIP_API=true; shift ;;
        --help|-h)
            echo "Usage: $0 [--recreate] [--skip-ui] [--skip-api]"
            exit 0
            ;;
        *) log_error "Unknown option: $1"; exit 1 ;;
    esac
done

load_goprepared_env "$SCRIPT_DIR"
init_proxmox_mode

RECREATE_FLAG=""
[[ "$RECREATE" == true ]] && RECREATE_FLAG="--recreate"

log_info "=== GoPrepared LXC full deploy ==="

if [[ "$SKIP_API" != true ]]; then
    "${SCRIPT_DIR}/deploy-api.sh" $RECREATE_FLAG
else
    log_info "Skipping API deploy"
fi

if [[ "$SKIP_UI" != true ]]; then
    "${SCRIPT_DIR}/deploy-ui.sh" --skip-container
else
    log_info "Skipping UI deploy"
fi

log_success "GoPrepared deployed to ${CONTAINER_NAME} (VMID ${VMID:-${FIXED_VMID}})"
if [[ -n "${TAILNET_DNS:-}" ]]; then
    log_info "  PWA:  http://${CONTAINER_NAME}.${TAILNET_DNS}/"
    log_info "  API:  http://${CONTAINER_NAME}.${TAILNET_DNS}/api/v1/"
else
    log_info "  PWA/API: http://${DOMAIN}/"
fi
