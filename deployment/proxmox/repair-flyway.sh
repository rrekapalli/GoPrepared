#!/bin/bash
# Fix Flyway checksum mismatch after migration files were edited post-deploy.
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
log_info "Repairing Flyway checksums on ${POSTGRES_HOST}/${POSTGRES_DB} ..."

REPAIR_SQL="UPDATE flyway_schema_history SET checksum = -1622945549 WHERE version = '1'; SELECT version, checksum FROM flyway_schema_history ORDER BY installed_rank;"

if command -v psql >/dev/null 2>&1; then
  export PGPASSWORD="${POSTGRES_PASSWORD}"
  psql -h "${POSTGRES_HOST}" -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" -v ON_ERROR_STOP=1 -c "$REPAIR_SQL"
else
  log_info "psql not local; running repair via LXC ${VMID} ..."
  proxmox_exec_in_container "$VMID" "command -v psql >/dev/null 2>&1 || (DEBIAN_FRONTEND=noninteractive apt-get update -qq && DEBIAN_FRONTEND=noninteractive apt-get install -y -qq postgresql-client)" || true
  proxmox_exec_in_container "$VMID" "PGPASSWORD='${POSTGRES_PASSWORD}' psql -h '${POSTGRES_HOST}' -U '${POSTGRES_USER}' -d '${POSTGRES_DB}' -v ON_ERROR_STOP=1 -c \"${REPAIR_SQL}\"" || exit 1
fi

log_success "Checksum repair applied for V1"
log_info "Restart API: ./deployment/proxmox/deploy-api.sh --skip-container"
