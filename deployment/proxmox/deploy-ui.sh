#!/bin/bash
# Deploy GoPrepared Flutter PWA (static) to nginx on LXC.
# Usage: ./deploy-ui.sh [--recreate] [path/to/pwa-dist.zip]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/deploy-logging.sh
source "${SCRIPT_DIR}/scripts/deploy-logging.sh"
# shellcheck source=lib/load-env.sh
source "${SCRIPT_DIR}/lib/load-env.sh" "$SCRIPT_DIR"
# shellcheck source=lib/proxmox-remote.sh
source "${SCRIPT_DIR}/lib/proxmox-remote.sh"
# shellcheck source=lib/pwa-zip.sh
source "${SCRIPT_DIR}/lib/pwa-zip.sh"

RECREATE=false
SKIP_CONTAINER=false
ZIP_PATH=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        --recreate) RECREATE=true; shift ;;
        --skip-container) SKIP_CONTAINER=true; shift ;;
        -*) log_error "Unknown option: $1"; exit 1 ;;
        *) ZIP_PATH="$1"; shift ;;
    esac
done

load_goprepared_env "$SCRIPT_DIR"
init_proxmox_mode

if [[ "$SKIP_CONTAINER" == true ]]; then
    VMID="$(proxmox_find_container_by_name "$CONTAINER_NAME" | tr -d '[:space:]')"
    [[ -n "$VMID" ]] || VMID="$FIXED_VMID"
    [[ -n "$VMID" ]] || { log_error "Container ${CONTAINER_NAME} not found"; exit 1; }
fi

if [[ -z "$CONTAINER_PASSWORD" ]]; then
    log_error "Set CONTAINER_PASSWORD in ${ENV_FILE}"
    exit 1
fi

if [[ -z "$ZIP_PATH" ]]; then
    ZIP_PATH="${ARTIFACTS_DIR}/pwa-dist.zip"
fi
[[ -f "$ZIP_PATH" ]] || { log_error "PWA zip not found: $ZIP_PATH. Run ./deploy.sh or ./deployment/prepare-artifacts.sh"; exit 1; }

log_info "=== GoPrepared PWA deploy ==="
log_info "Zip: $ZIP_PATH"

ensure_linux_pwa_zip "$ZIP_PATH"

if [[ "$SKIP_CONTAINER" != true ]]; then
    ensure_goprepared_container "$RECREATE"
    ensure_lxc_tailscale_prereqs "$VMID"
    bootstrap_container_basics "$VMID"
    ensure_nginx "$VMID"
fi

log_info "Preparing web root ${WEB_ROOT}..."
proxmox_exec_in_container "$VMID" "mkdir -p ${WEB_ROOT} && rm -rf ${WEB_ROOT}/*" || true

REMOTE_ZIP="/tmp/pwa-dist.zip"
proxmox_push_file "$VMID" "$ZIP_PATH" "$REMOTE_ZIP"
proxmox_exec_in_container "$VMID" "unzip -o -q ${REMOTE_ZIP} -d ${WEB_ROOT} && rm -f ${REMOTE_ZIP} && chown -R www-data:www-data ${WEB_ROOT}" || exit 1

NGINX_TEMPLATE="${SCRIPT_DIR}/nginx/goprepared.conf.template"
[[ -f "$NGINX_TEMPLATE" ]] || { log_error "Missing nginx template"; exit 1; }
NGINX_CONF=$(sed -e "s|__DOMAIN__|${DOMAIN}|g" -e "s|__WEB_ROOT__|${WEB_ROOT}|g" -e "s|__API_PORT__|${API_PORT}|g" "$NGINX_TEMPLATE")
TMP_NGINX="/tmp/goprepared-nginx.conf"
echo "$NGINX_CONF" > "$TMP_NGINX"
proxmox_push_file "$VMID" "$TMP_NGINX" "/etc/nginx/sites-available/goprepared"
rm -f "$TMP_NGINX"

proxmox_exec_in_container "$VMID" "ln -sf /etc/nginx/sites-available/goprepared /etc/nginx/sites-enabled/goprepared && rm -f /etc/nginx/sites-enabled/default && nginx -t && systemctl reload nginx 2>/dev/null || systemctl restart nginx" || exit 1

if proxmox_exec_in_container "$VMID" "curl -sf -o /dev/null -w '%{http_code}' http://127.0.0.1:${UI_PORT}/" 2>/dev/null | grep -qE '200|304'; then
    log_success "PWA serving on port ${UI_PORT}"
else
    log_warn "HTTP curl check inconclusive; verify manually"
fi

if [[ "$SKIP_CONTAINER" != true ]]; then
    goprepared_final_tailscale "$SCRIPT_DIR" "$VMID" "$CONTAINER_NAME"
fi

log_success "PWA deployed to ${CONTAINER_NAME} (VMID ${VMID})"
log_info "  http://${DOMAIN}/"
