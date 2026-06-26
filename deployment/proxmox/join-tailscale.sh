#!/bin/bash
# Join goprepared LXC to Tailscale.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/load-env.sh
source "${SCRIPT_DIR}/lib/load-env.sh" "$SCRIPT_DIR"
load_goprepared_env "$SCRIPT_DIR"
exec "${SCRIPT_DIR}/add-lxc-to-tailscale.sh" "$FIXED_VMID" "$CONTAINER_NAME"
