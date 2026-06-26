#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../go-prepared-content"
pip install -e . -q
python -m goprepared_content.cli all
