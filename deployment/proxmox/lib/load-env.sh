# shellcheck shell=bash
# Load deployment.conf and workspace .env.

strip_cr() {
    printf '%s' "$1" | tr -d '\r'
}

load_goprepared_env() {
    local script_dir="${1:?}"
    DEPLOYMENT_DIR="$(cd "${script_dir}/.." && pwd)"
    ROOT_DIR="$(cd "${DEPLOYMENT_DIR}/.." && pwd)"
    CONFIG_FILE="${DEPLOYMENT_DIR}/proxmox/deployment.conf"
    ENV_FILE="${ROOT_DIR}/.env"
    ARTIFACTS_DIR="${DEPLOYMENT_DIR}/artifacts"
    APP_DIR="${ROOT_DIR}/go-prepared-app"
    API_DIR="${ROOT_DIR}/go-prepared-api"
    CONTENT_DIR="${ROOT_DIR}/go-prepared-content"

    if [[ -f "$CONFIG_FILE" ]]; then
        set -a
        # shellcheck disable=SC1090
        source <(grep -v '^#' "$CONFIG_FILE" | grep -v '^$' | grep '=' | tr -d '\r') 2>/dev/null || true
        set +a
    fi

    if [[ -f "$ENV_FILE" ]]; then
        set -a
        while IFS= read -r line || [[ -n "$line" ]]; do
            line="${line%$'\r'}"
            [[ "$line" =~ ^[[:space:]]*# ]] && continue
            [[ -z "${line// }" ]] && continue
            [[ ! "$line" =~ = ]] && continue
            eval "export $line" 2>/dev/null || true
        done < "$ENV_FILE"
        set +a
    fi

    CONTAINER_NAME="$(strip_cr "${GOPREPARED_CONTAINER_NAME:-goprepared}")"
    FIXED_VMID="$(strip_cr "${GOPREPARED_VMID:-7003}")"
    DOMAIN="$(strip_cr "${GOPREPARED_HOST:-goprepared.tailce422e.ts.net}")"
    UI_PORT="$(strip_cr "${UI_PORT:-80}")"
    API_PORT="$(strip_cr "${API_PORT:-8080}")"
    CLONE_TEMPLATE="$(strip_cr "${GOPREPARED_CLONE_TEMPLATE:-moneytree-lxc-base}")"
    CORES="$(strip_cr "${GOPREPARED_CORES:-2}")"
    MEMORY_MB="$(strip_cr "${GOPREPARED_MEMORY_MB:-2048}")"
    ROOTFS_GB="$(strip_cr "${GOPREPARED_ROOTFS_GB:-16}")"
    CONTAINER_USER="$(strip_cr "${CONTAINER_USER:-${SSH_USER:-raja}}")"
    CONTAINER_PASSWORD="$(strip_cr "${CONTAINER_PASSWORD:-${SSH_PASSWORD:-}}")"
    SSH_USER="$(strip_cr "${SSH_USER:-${CONTAINER_USER:-raja}}")"
    SSH_PASSWORD="$(strip_cr "${SSH_PASSWORD:-${CONTAINER_PASSWORD:-}}")"
    # Re-sync after fallbacks so chpasswd and direct SSH always match.
    CONTAINER_USER="$SSH_USER"
    CONTAINER_PASSWORD="$SSH_PASSWORD"
    WEB_ROOT="$(strip_cr "${GOPREPARED_WEB_ROOT:-/var/www/goprepared}")"
    API_HOME="$(strip_cr "${GOPREPARED_API_HOME:-/opt/goprepared/go-prepared-api}")"
    CONTENT_ROOT="$(strip_cr "${GOPREPARED_CONTENT_ROOT:-/opt/goprepared/go-prepared-content}")"
    PROXMOX_HOST="$(strip_cr "${PROXMOX_HOST:-192.168.29.231}")"
    PROXMOX_USER="$(strip_cr "${PROXMOX_USER:-root}")"
    PROXMOX_PASSWORD="$(strip_cr "${PROXMOX_PASSWORD:-}")"
    LXC_ROOTFS_STORAGE="$(strip_cr "${LXC_ROOTFS_STORAGE:-local-storage}")"
    CLONE_TEMPLATE_VMID="$(strip_cr "${CLONE_TEMPLATE_VMID:-9001}")"
    TAILNET_DNS="$(strip_cr "${TAILNET_DNS:-}")"

    # Direct SSH to LXC on tailnet (MagicDNS or GOPREPARED_HOST)
    LXC_SSH_HOST="$(strip_cr "${DOMAIN}")"
    if [[ -z "$LXC_SSH_HOST" && -n "$TAILNET_DNS" ]]; then
        LXC_SSH_HOST="${CONTAINER_NAME}.${TAILNET_DNS}"
    fi
    LXC_SSH_OPTS="-o StrictHostKeyChecking=no -o ConnectTimeout=15 -o ServerAliveInterval=30"

    # PWA production build: API served via nginx on same host
    local host="${DOMAIN#http://}"
    host="${host#https://}"
    host="${host%%/*}"
    GOPREPARED_HTTPS="$(strip_cr "${GOPREPARED_HTTPS:-}")"
    if [[ -z "$GOPREPARED_HTTPS" && "$host" == *".ts.net" ]]; then
        GOPREPARED_HTTPS="true"
    fi
    if [[ "$GOPREPARED_HTTPS" == "true" || "$GOPREPARED_HTTPS" == "1" ]]; then
        PWA_API_BASE_URL="https://${host}/api/v1"
        PWA_PUBLIC_URL="https://${host}"
    else
        PWA_API_BASE_URL="http://${host}/api/v1"
        PWA_PUBLIC_URL="http://${host}"
    fi
    TLS_DIR="$(strip_cr "${GOPREPARED_TLS_DIR:-/etc/goprepared/tls}")"
    TLS_CERT="${TLS_DIR}/${host}.crt"
    TLS_KEY="${TLS_DIR}/${host}.key"
}
