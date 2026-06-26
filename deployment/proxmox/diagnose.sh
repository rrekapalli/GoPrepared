#!/bin/bash
# Quick health check for goprepared LXC (VMID 7003) on Proxmox.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/deploy-logging.sh
source "${SCRIPT_DIR}/scripts/deploy-logging.sh"
# shellcheck source=lib/load-env.sh
source "${SCRIPT_DIR}/lib/load-env.sh" "$SCRIPT_DIR"
# shellcheck source=lib/proxmox-remote.sh
source "${SCRIPT_DIR}/lib/proxmox-remote.sh"

load_goprepared_env "$SCRIPT_DIR"
init_proxmox_mode

VMID="${FIXED_VMID}"
log_info "Diagnosing ${CONTAINER_NAME} (VMID ${VMID}) on ${PROXMOX_HOST}..."

run() {
    proxmox_exec_in_container "$VMID" "$1" 2>&1 || echo "(command failed)"
}

if ! proxmox_container_exists "$CONTAINER_NAME"; then
    log_error "Container '${CONTAINER_NAME}' not found on Proxmox"
    exit 1
fi

log_info "--- container status ---"
if [[ "$USE_REMOTE_PROXMOX" == true ]]; then
    _proxmox_remote "pct status ${VMID}" || true
else
    pct status "$VMID" || true
fi

log_info "--- tailscale ---"
run "tailscale status 2>&1 | head -20"
run "tailscale ip -4 2>&1"
run "systemctl is-active tailscaled 2>&1"
run "systemctl is-active tailscale-autojoin 2>&1"

log_info "--- nginx / pwa ---"
run "systemctl is-active nginx 2>&1"
run "curl -sI --max-time 5 http://127.0.0.1:${UI_PORT}/ 2>&1 | head -8"
run "test -f ${WEB_ROOT}/index.html && echo index.html:ok || echo index.html:MISSING"

log_info "--- api (systemd) ---"
run "systemctl is-active goprepared-api 2>&1"
run "curl -sf --max-time 5 http://127.0.0.1:${API_PORT}/api/v1/knowledge/categories 2>&1 | head -c 200"
run "journalctl -u goprepared-api -n 15 --no-pager 2>&1"

log_info "--- lxc ssh (${SSH_USER}@${LXC_SSH_HOST:-${DOMAIN:-unknown}}) ---"
if [[ -n "${SSH_PASSWORD:-}" ]] && command -v sshpass >/dev/null 2>&1; then
    lxc_ssh "hostname && uptime" 2>&1 || echo "(ssh failed — is Tailscale up on the LXC?)"
else
    log_info "Set SSH_PASSWORD in .env for direct LXC SSH checks"
fi

log_info "--- firewall ---"
run "ufw status 2>&1 | head -12"

log_info "--- tun (required for Tailscale in LXC) ---"
run "test -c /dev/net/tun && echo /dev/net/tun:ok || echo /dev/net/tun:MISSING"
