$ErrorActionPreference = "Stop"
Set-Location "$PSScriptRoot\..\go-prepared-content"
python -m pip install -e . -q
python -m goprepared_content.cli all
