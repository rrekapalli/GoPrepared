$ErrorActionPreference = "Stop"
Set-Location "$PSScriptRoot\..\deployment\docker"
docker compose down
