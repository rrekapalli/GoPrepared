#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
powershell.exe -File ./import-content.ps1 2>/dev/null || python3 -c "print('Use import via API ContentImportConfig on startup')"
