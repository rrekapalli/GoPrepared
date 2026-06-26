# shellcheck shell=bash
# Normalize pwa-dist.zip for Linux unzip (PowerShell Compress-Archive uses backslash paths).

pwa_zip_has_backslashes() {
    local zip="$1"
    python3 - "$zip" <<'PY'
import sys, zipfile
with zipfile.ZipFile(sys.argv[1]) as z:
    raise SystemExit(0 if any("\\" in n for n in z.namelist()) else 1)
PY
}

repack_pwa_zip_for_linux() {
    local zip="$1"
    python3 - "$zip" <<'PY'
import sys, zipfile
from pathlib import Path

path = Path(sys.argv[1])
with zipfile.ZipFile(path) as z:
    if not any("\\" in n for n in z.namelist()):
        sys.exit(0)
    tmp = path.with_suffix(".linux.zip")
    with zipfile.ZipFile(tmp, "w", compression=zipfile.ZIP_DEFLATED) as out:
        for member in z.infolist():
            name = member.filename.replace("\\", "/")
            if name.endswith("/"):
                continue
            out.writestr(name, z.read(member))
    tmp.replace(path)
    print(f"Repacked {path} with Unix path separators", file=sys.stderr)
PY
}

ensure_linux_pwa_zip() {
    local zip="$1"
    command -v python3 >/dev/null 2>&1 || {
        log_error "python3 required to normalize Windows-built pwa-dist.zip"
        exit 1
    }
    if ! command -v jq >/dev/null 2>&1; then
        log_warn "jq not found — Tailscale hostname dedupe via API will be skipped."
        log_warn "Install jq (e.g. sudo dnf install jq) so MagicDNS gets the canonical hostname."
    fi
    if pwa_zip_has_backslashes "$zip"; then
        log_warn "Windows zip detected (backslash paths); repacking for Linux..."
        repack_pwa_zip_for_linux "$zip"
    fi
}
