#!/bin/bash
# Deploy GoPrepared Spring Boot API to LXC (systemd + env from workspace .env).
# Usage: ./deploy-api.sh [--recreate] [path/to/go-prepared-api.jar]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/deploy-logging.sh
source "${SCRIPT_DIR}/scripts/deploy-logging.sh"
# shellcheck source=lib/load-env.sh
source "${SCRIPT_DIR}/lib/load-env.sh" "$SCRIPT_DIR"
# shellcheck source=lib/proxmox-remote.sh
source "${SCRIPT_DIR}/lib/proxmox-remote.sh"

RECREATE=false
SKIP_CONTAINER=false
JAR_PATH=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        --recreate) RECREATE=true; shift ;;
        --skip-container) SKIP_CONTAINER=true; shift ;;
        -*) log_error "Unknown option: $1"; exit 1 ;;
        *) JAR_PATH="$1"; shift ;;
    esac
done

load_goprepared_env "$SCRIPT_DIR"
init_proxmox_mode

if [[ -z "${CONTAINER_PASSWORD:-}" ]]; then
    log_error "Set CONTAINER_PASSWORD in ${ENV_FILE}"
    exit 1
fi

if [[ -z "$JAR_PATH" ]]; then
    JAR_PATH="${ARTIFACTS_DIR}/go-prepared-api.jar"
fi
[[ -f "$JAR_PATH" ]] || { log_error "API jar not found: $JAR_PATH. Run ./deploy.sh or ./deployment/prepare-artifacts.sh"; exit 1; }

CONTENT_OUTPUT="${CONTENT_DIR}/output"
[[ -d "$CONTENT_OUTPUT" ]] || log_warn "Static content missing at ${CONTENT_OUTPUT}; run: cd go-prepared-content && python -m goprepared_content.cli all"

log_info "=== GoPrepared API deploy (systemd) ==="
log_info "Jar: $JAR_PATH"

VMID="${FIXED_VMID}"
if [[ "$SKIP_CONTAINER" != true ]]; then
    ensure_goprepared_container "$RECREATE"
    VMID="${VMID:-$FIXED_VMID}"
    ensure_lxc_tailscale_prereqs "$VMID"
    bootstrap_container_basics "$VMID"
    ensure_java "$VMID"
    ensure_goprepared_user "$VMID"
fi

# Retire podman deployment if present (legacy)
proxmox_exec_in_container "$VMID" "podman rm -f goprepared-api 2>/dev/null || true" || true

REMOTE_JAR="/tmp/go-prepared-api.jar"
proxmox_push_file "$VMID" "$JAR_PATH" "$REMOTE_JAR"
proxmox_exec_in_container "$VMID" "mv ${REMOTE_JAR} ${API_HOME}/go-prepared-api.jar && chown goprepared:goprepared ${API_HOME}/go-prepared-api.jar" || exit 1

if [[ -d "$CONTENT_OUTPUT" ]]; then
    log_info "Syncing static content to ${CONTENT_ROOT}/output ..."
    proxmox_push_dir "$VMID" "$CONTENT_OUTPUT" "${CONTENT_ROOT}/output"
    proxmox_exec_in_container "$VMID" "chown -R goprepared:goprepared ${CONTENT_ROOT}" || true
fi

ENV_TMP="/tmp/goprepared-api.env"
cat > "$ENV_TMP" <<EOF
POSTGRES_HOST=${POSTGRES_HOST:-pg18.tailce422e.ts.net}
POSTGRES_PORT=${POSTGRES_PORT:-5432}
POSTGRES_DB=${POSTGRES_DB:-goprepared}
POSTGRES_USER=${POSTGRES_USER:-postgres}
POSTGRES_PASSWORD=${POSTGRES_PASSWORD:-}
API_PORT=${API_PORT:-8080}
JWT_SECRET=${JWT_SECRET:-change-me-in-production}
GOOGLE_CLIENT_ID=${GOOGLE_CLIENT_ID:-}
GOPREPARED_AI_PROVIDER=${GOPREPARED_AI_PROVIDER:-ollama}
OLLAMA_BASE_URL=${OLLAMA_BASE_URL:-http://ollama.tailce422e.ts.net}
OLLAMA_MODEL=${OLLAMA_MODEL:-llama3.2}
OPENAI_API_KEY=${OPENAI_API_KEY:-}
MICROSOFT_CLIENT_ID=${MICROSOFT_CLIENT_ID:-}
MICROSOFT_TENANT_ID=${MICROSOFT_TENANT_ID:-common}
GOPREPARED_AUTH_DEV_ENABLED=${GOPREPARED_AUTH_DEV_ENABLED:-false}
GOPREPARED_CORS_ORIGINS=${GOPREPARED_CORS_ORIGINS:-http://localhost:*,http://127.0.0.1:*,http://goprepared.*,https://goprepared.*,https://*.tailce422e.ts.net}
GOPREPARED_CONTENT_SYNC_ON_STARTUP=true
GOPREPARED_CONTENT_CONTENT_PATH=${CONTENT_ROOT}/output
EOF
proxmox_push_file "$VMID" "$ENV_TMP" "/etc/goprepared/api.env"
rm -f "$ENV_TMP"
proxmox_exec_in_container "$VMID" "chmod 600 /etc/goprepared/api.env" || true

SYSTEMD_TMP="/tmp/goprepared-api.service"
cat > "$SYSTEMD_TMP" <<EOF
[Unit]
Description=GoPrepared Spring Boot API
After=network.target
Wants=network-online.target

[Service]
Type=simple
User=goprepared
Group=goprepared
WorkingDirectory=${API_HOME}
EnvironmentFile=/etc/goprepared/api.env
ExecStart=/usr/bin/java -jar ${API_HOME}/go-prepared-api.jar
Restart=on-failure
RestartSec=10
SuccessExitStatus=143

[Install]
WantedBy=multi-user.target
EOF
proxmox_push_file "$VMID" "$SYSTEMD_TMP" "/etc/systemd/system/goprepared-api.service"
rm -f "$SYSTEMD_TMP"

proxmox_exec_in_container "$VMID" "systemctl daemon-reload && systemctl enable goprepared-api && systemctl restart goprepared-api" || exit 1

log_info "Waiting for API health..."
for i in $(seq 1 45); do
    if proxmox_exec_in_container "$VMID" "curl -sf -o /dev/null http://127.0.0.1:${API_PORT}/api/v1/knowledge/categories 2>/dev/null"; then
        log_success "API responding on port ${API_PORT}"
        break
    fi
    [[ "$i" -eq 45 ]] && log_warn "API health check timed out; check: pct exec ${VMID} -- journalctl -u goprepared-api -n 50"
    sleep 2
done

if [[ "$SKIP_CONTAINER" != true ]]; then
    goprepared_final_tailscale "$SCRIPT_DIR" "$VMID" "$CONTAINER_NAME"
fi

log_success "API deployed to ${CONTAINER_NAME} (VMID ${VMID})"
log_info "  http://${DOMAIN}/api/v1/"
