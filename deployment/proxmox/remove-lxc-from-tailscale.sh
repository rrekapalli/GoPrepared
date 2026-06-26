#!/bin/bash
# Remove an LXC container's node from the Tailscale tailnet so the hostname can be re-used.
# 1) Runs "tailscale logout" inside the container (if running) to disconnect.
# 2) If TAILSCALE_API_KEY and hostname are set, deletes the device via Tailscale Admin API
#    so the hostname is freed (logout alone leaves the device as inactive and keeps the name).
#
# Usage:
#   ./remove-lxc-from-tailscale.sh <VMID> [hostname]
#   ./remove-lxc-from-tailscale.sh 8007
#   ./remove-lxc-from-tailscale.sh 8007 moneytree
#   ./remove-lxc-from-tailscale.sh 8002 moneytree-gateway
#
# Run on Proxmox host or with PROXMOX_HOST, PROXMOX_USER, PROXMOX_PASSWORD set.
# For API delete (hostname reuse): set TAILSCALE_API_KEY in .env (Admin API token from
# https://login.tailscale.com/admin/settings/keys) and TAILNET_DNS (e.g. tailce422e.ts.net).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"
CONFIG_FILE="${SCRIPT_DIR}/deployment.conf"
ENV_FILE="${ROOT_DIR}/.env"

ARG="${1:-}"
CLI_HOSTNAME="${2:-}"
HOSTNAME="${CLI_HOSTNAME}"
if [[ -z "$ARG" ]] || [[ ! "$ARG" =~ ^[0-9]+$ ]]; then
    echo "Usage: $0 <VMID> [hostname]" >&2
    echo "  Example: $0 8007" >&2
    echo "  Example: $0 8007 moneytree" >&2
    echo "  Example: $0 8002 moneytree-gateway" >&2
    exit 1
fi
VMID="$ARG"

if [[ -f "$CONFIG_FILE" ]]; then
    set -a
    source <(grep -v '^#' "$CONFIG_FILE" | grep -v '^$' | grep '=' | tr -d '\r') 2>/dev/null || true
    set +a
fi
if [[ -f "$ENV_FILE" ]]; then
    set -a
    source <(grep -v '^#' "$ENV_FILE" | grep -v '^$' | grep '=' | tr -d '\r') 2>/dev/null || true
    set +a
fi
# Sourcing .env/deployment.conf can set HOSTNAME (machine name); never override an explicit CLI hostname.
if [[ -n "${CLI_HOSTNAME:-}" ]]; then
    HOSTNAME="$CLI_HOSTNAME"
fi

run_on_host() {
    local cmd="$1"
    if command -v pct > /dev/null 2>&1; then
        bash -c "$cmd"
    elif [[ -n "${PROXMOX_HOST:-}" ]] && [[ -n "${PROXMOX_USER:-}" ]]; then
        if [[ -n "${PROXMOX_PASSWORD:-}" ]] && command -v sshpass > /dev/null 2>&1; then
            sshpass -p "$PROXMOX_PASSWORD" ssh -o StrictHostKeyChecking=no "${PROXMOX_USER}@${PROXMOX_HOST}" "$cmd"
        else
            ssh -o StrictHostKeyChecking=no "${PROXMOX_USER}@${PROXMOX_HOST}" "$cmd"
        fi
    else
        echo "ERROR: Run this script on the Proxmox host or set PROXMOX_HOST and PROXMOX_USER." >&2
        exit 1
    fi
}

# Step 1: Logout from inside the container (if container is still running)
echo "[remove-lxc-from-tailscale] Logging out VMID $VMID from tailnet (in-container logout)..."
if run_on_host "pct status $VMID 2>/dev/null | awk '{print \$2}'" 2>/dev/null | grep -q running; then
    run_on_host "pct exec $VMID -- tailscale logout 2>/dev/null" || true
else
    echo "[remove-lxc-from-tailscale] Container $VMID not running; skipping in-container logout."
fi
echo "[remove-lxc-from-tailscale] Waiting for tailnet to process logout..."
sleep 3

# Resolve hostname if not provided (for API delete): try container hostname
if [[ -z "$HOSTNAME" ]] && run_on_host "pct status $VMID 2>/dev/null | awk '{print \$2}'" 2>/dev/null | grep -q running; then
    HOSTNAME=$(run_on_host "pct exec $VMID -- hostname 2>/dev/null" 2>/dev/null | tr -d '[:space:]') || true
fi

# Step 2: Delete device(s) via Tailscale Admin API so hostname is freed (not just inactive)
# Match exact hostname OR hostname-1, hostname-2 etc. so we remove all duplicates and free the base name.
TAILNET="${TAILNET_DNS:-${TAILNET:-}}"
if [[ -z "$TAILNET" ]] && [[ -n "${GATEWAY_DOMAIN:-}" ]]; then
    TAILNET=$(echo "$GATEWAY_DOMAIN" | sed -n 's/^[^.]*\.\(.*\)$/\1/p')
fi
if [[ -z "$TAILNET" ]] && [[ -n "${FRONTEND_HOST:-}" ]]; then
    TAILNET=$(echo "$FRONTEND_HOST" | sed -n 's/^[^.]*\.\(.*\)$/\1/p')
fi

if [[ -n "${TAILSCALE_API_KEY:-}" ]] && [[ "${TAILSCALE_API_KEY}" != tskey-api-* ]]; then
    echo "[remove-lxc-from-tailscale] TAILSCALE_API_KEY must start with tskey-api- (Admin API). Skipping API delete." >&2
    TAILSCALE_API_KEY=""
fi

if [[ -n "${TAILSCALE_API_KEY:-}" ]] && [[ -n "$HOSTNAME" ]] && [[ -n "$TAILNET" ]]; then
    if command -v curl > /dev/null 2>&1 && command -v jq > /dev/null 2>&1; then
        echo "[remove-lxc-from-tailscale] Deleting device(s) matching '$HOSTNAME' from tailnet via API (so hostname can be re-used)..."
        DEVICES_JSON=""
        HTTP_CODE="000"
        # Try tailnet as-is (e.g. tailce422e.ts.net); then without .ts.net (e.g. tailce422e) if API expects short name
        for TAILNET_TRY in "$TAILNET" "${TAILNET%%.ts.net}"; do
            [[ -z "$TAILNET_TRY" ]] && continue
            HTTP_CODE=$(curl -s -o /tmp/ts-devices-$$.json -w "%{http_code}" -u "${TAILSCALE_API_KEY}:" "https://api.tailscale.com/api/v2/tailnet/${TAILNET_TRY}/devices" 2>/dev/null) || true
            if [[ "$HTTP_CODE" == "200" ]] && [[ -s /tmp/ts-devices-$$.json ]]; then
                DEVICES_JSON=$(cat /tmp/ts-devices-$$.json)
                break
            fi
        done
        rm -f /tmp/ts-devices-$$.json 2>/dev/null || true

        if [[ -n "$DEVICES_JSON" ]]; then
            # Match ONLY: exact hostname or hostname-N (duplicate suffix). Do NOT match other services (e.g. for
            # HOSTNAME=moneytree match moneytree and moneytree-1, moneytree-2; do NOT match moneytree-admin, moneytree-gateway).
            # API returns .name as FQDN (e.g. moneytree-gateway.tailce422e.ts.net); compare first label (short name).
            MATCHING_IDS=$(echo "$DEVICES_JSON" | jq -r --arg h "$HOSTNAME" '
                def short: if type == "string" then (split(".")[0] // "") else "" end;
                def is_dup: (type == "string") and startswith($h + "-") and ((ltrimstr($h + "-") | length > 0) and (ltrimstr($h + "-") | test("^[0-9]+$")));
                .devices[]? | select(
                    ((.name | short) == $h) or ((.hostname | short) == $h) or
                    ((.name | short) | is_dup) or ((.hostname | short) | is_dup)
                ) | .id
            ' 2>/dev/null) || true
            DELETED=0
            while IFS= read -r DEVICE_ID; do
                [[ -z "$DEVICE_ID" ]] || [[ "$DEVICE_ID" == "null" ]] && continue
                DEVICE_NAME=$(echo "$DEVICES_JSON" | jq -r --arg id "$DEVICE_ID" '.devices[]? | select(.id == $id) | .name // .hostname // .id' 2>/dev/null) || echo "$DEVICE_ID"
                if curl -s -o /dev/null -w "%{http_code}" -X DELETE -u "${TAILSCALE_API_KEY}:" "https://api.tailscale.com/api/v2/device/${DEVICE_ID}" 2>/dev/null | grep -q '^200\|^204'; then
                    echo "[remove-lxc-from-tailscale] Deleted device '$DEVICE_NAME' (id $DEVICE_ID); hostname freed for re-use."
                    DELETED=$((DELETED + 1))
                else
                    echo "[remove-lxc-from-tailscale] Failed to delete device '$DEVICE_NAME' (id $DEVICE_ID)." >&2
                fi
            done <<< "$MATCHING_IDS"
            if [[ "$DELETED" -eq 0 ]] && [[ -z "$MATCHING_IDS" ]]; then
                echo "[remove-lxc-from-tailscale] No device named '$HOSTNAME' or '$HOSTNAME-<digits>' found in tailnet (may already be removed or name differs in API)."
            fi
        else
            echo "[remove-lxc-from-tailscale] Could not list devices (HTTP $HTTP_CODE). Check TAILSCALE_API_KEY and TAILNET_DNS (e.g. tailce422e.ts.net) in .env." >&2
        fi
    else
        echo "[remove-lxc-from-tailscale] curl and jq required for API delete. Install them or remove device manually from admin console." >&2
    fi
else
    if [[ -z "${TAILSCALE_API_KEY:-}" ]]; then
        echo "[remove-lxc-from-tailscale] TAILSCALE_API_KEY not set. Add an Admin API token to .env to auto-delete the device and free the hostname. Otherwise remove the device from https://login.tailscale.com/admin/machines to avoid -1, -2 suffixes on re-join."
    fi
    if [[ -z "$HOSTNAME" ]]; then
        echo "[remove-lxc-from-tailscale] Hostname not provided and container not running; could not delete by name. Pass hostname as second argument when using --recreate."
    fi
fi

echo "[remove-lxc-from-tailscale] Waiting for tailnet to process removal..."
sleep 5
echo "[remove-lxc-from-tailscale] Done."
