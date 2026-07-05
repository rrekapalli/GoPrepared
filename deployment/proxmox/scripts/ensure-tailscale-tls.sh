#!/bin/bash
# Issue or refresh Tailscale TLS certs for MagicDNS (Azure Entra requires https:// redirect URIs).
# Requires: HTTPS enabled in Tailscale admin → DNS, tailscale running in the LXC.

ensure_tailscale_tls() {
    local vmid="${1:?vmid required}"
    local domain="${2:?domain required}"
    local tls_dir="/etc/goprepared/tls"
    local cert_file="${tls_dir}/${domain}.crt"
    local key_file="${tls_dir}/${domain}.key"

    if ! proxmox_exec_in_container "$vmid" "command -v tailscale >/dev/null 2>&1"; then
        log_warn "tailscale not installed in LXC — skipping HTTPS (use HTTP-only or install Tailscale)"
        return 1
    fi

    if ! proxmox_exec_in_container "$vmid" "tailscale status >/dev/null 2>&1"; then
        log_warn "tailscale not connected — skipping HTTPS cert issue"
        return 1
    fi

    log_info "Issuing Tailscale TLS cert for ${domain} ..."
    proxmox_exec_in_container "$vmid" "mkdir -p ${tls_dir} && tailscale cert --cert-file ${cert_file} --key-file ${key_file} ${domain} && chmod 644 ${cert_file} && chmod 600 ${key_file}" || {
        log_warn "tailscale cert failed. Enable HTTPS in https://login.tailscale.com/admin/dns and retry."
        return 1
    }

    proxmox_exec_in_container "$vmid" "test -f ${cert_file} && test -f ${key_file}" || return 1
    log_success "TLS cert ready: ${cert_file}"
    return 0
}
