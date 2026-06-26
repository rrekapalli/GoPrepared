# Start GoPrepared locally: Docker infra (optional) + Spring API + Flutter web
$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $PSScriptRoot

Write-Host "=== GoPrepared local dev ===" -ForegroundColor Cyan

# 1. Optional Docker (Postgres + Ollama) — skip if using remote DB from .env
if (Get-Command docker -ErrorAction SilentlyContinue) {
    Write-Host "Starting Docker infra (Postgres + Ollama)..."
    & "$Root\scripts\dev-up.ps1"
} else {
    Write-Host "Docker not found — using POSTGRES_* from .env (remote DB OK)" -ForegroundColor Yellow
}

# 2. Check if API already running
$apiUp = $false
try {
    $r = Invoke-WebRequest -Uri "http://localhost:8080/api/v1/knowledge/categories" -UseBasicParsing -TimeoutSec 3
    if ($r.StatusCode -eq 200) { $apiUp = $true }
} catch {}

if (-not $apiUp) {
    Write-Host "Starting Spring Boot API on http://localhost:8080 ..."
    $apiJob = Start-Job -ScriptBlock {
        Set-Location $using:Root\go-prepared-api
        & .\mvnw.cmd spring-boot:run 2>&1
    }
    Write-Host "Waiting for API (up to 90s)..."
    for ($i = 0; $i -lt 45; $i++) {
        Start-Sleep -Seconds 2
        try {
            $r = Invoke-WebRequest -Uri "http://localhost:8080/api/v1/knowledge/categories" -UseBasicParsing -TimeoutSec 3
            if ($r.StatusCode -eq 200) {
                $apiUp = $true
                Write-Host "API is ready." -ForegroundColor Green
                break
            }
        } catch {}
    }
    if (-not $apiUp) {
        Write-Host "API did not start in time. Check: Receive-Job -Id $($apiJob.Id)" -ForegroundColor Red
        Write-Host "Or run manually: cd go-prepared-api; .\mvnw.cmd spring-boot:run"
    }
} else {
    Write-Host "API already running on :8080" -ForegroundColor Green
}

# 3. Flutter web
Write-Host "Starting Flutter web..."
Set-Location "$Root\go-prepared-app"
flutter run -d chrome
