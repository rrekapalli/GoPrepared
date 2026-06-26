$ErrorActionPreference = "Stop"
Set-Location "$PSScriptRoot\..\deployment\docker"
docker compose up -d postgres ollama
Write-Host "Waiting for Postgres..."
Start-Sleep -Seconds 5
Write-Host "Run deployment/docker/ollama/pull-models.sh inside ollama container or: docker exec goprepared-ollama ollama pull llama3.2"
