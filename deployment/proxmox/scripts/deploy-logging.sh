# Timestamped logging for deploy scripts.
RED="${RED:-\033[0;31m}"
GREEN="${GREEN:-\033[0;32m}"
YELLOW="${YELLOW:-\033[1;33m}"
BLUE="${BLUE:-\033[0;34m}"
CYAN="${CYAN:-\033[0;36m}"
NC="${NC:-\033[0m}"

_log_ts() { date '+%H:%M:%S'; }
log_info() { echo -e "$(_log_ts) ${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "$(_log_ts) ${GREEN}[SUCCESS]${NC} $1"; }
log_warn() { echo -e "$(_log_ts) ${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "$(_log_ts) ${RED}[ERROR]${NC} $1"; }
log_prompt() { echo -e "$(_log_ts) ${CYAN}[?]${NC} $1"; }

goprepared_final_tailscale() {
    local d="${1:?}" vmid="${2:?}" cname="${3:?}"
    local ts_script="${d}/add-lxc-to-tailscale.sh"
    if [[ ! -x "$ts_script" ]]; then
        log_warn "add-lxc-to-tailscale.sh not found; skip Tailscale join"
        return 0
    fi

    log_info "Tailscale join (idempotent)..."
    if ! "$ts_script" "$vmid" "$cname"; then
        log_error "Tailscale join script failed for VMID ${vmid}"
        exit 1
    fi

    local ts_ip=""
    ts_ip="$(proxmox_exec_in_container "$vmid" "tailscale ip -4 2>/dev/null | head -1" | tr -d '[:space:]')"
    if [[ ! "$ts_ip" =~ ^100\. ]]; then
        log_error "Tailscale is not connected on ${cname} (VMID ${vmid})."
        log_error "Check: pct exec ${vmid} -- journalctl -u tailscale-autojoin -n 50 --no-pager"
        log_error "Retry: ${d}/join-tailscale.sh"
        exit 1
    fi

    log_success "Tailscale connected: ${ts_ip}"
    if [[ -n "${TAILNET_DNS:-}" ]]; then
        log_info "Open: http://${cname}.${TAILNET_DNS}/  (use http, not https)"
    else
        log_info "Open: http://${ts_ip}/"
    fi
}
