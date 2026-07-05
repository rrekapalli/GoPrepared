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

# 2. Check if API already running (and has current routes)
function Test-ApiReady {
    try {
        $r = Invoke-WebRequest -Uri "http://localhost:8080/api/v1/knowledge/templates?journeyType=Travel" -UseBasicParsing -TimeoutSec 5
        return $r.StatusCode -eq 200
    } catch {
        return $false
    }
}

$apiUp = Test-ApiReady
if ($apiUp) {
    Write-Host "API already running on :8080" -ForegroundColor Green
} else {
    # Stale process may answer /categories but not /templates — free the port
    $portPid = (Get-NetTCPConnection -LocalPort 8080 -State Listen -ErrorAction SilentlyContinue | Select-Object -First 1).OwningProcess
    if ($portPid) {
        Write-Host "Stopping stale API on :8080 (PID $portPid)..." -ForegroundColor Yellow
        Stop-Process -Id $portPid -Force -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 2
    }

    Write-Host "Starting Spring Boot API on http://localhost:8080 ..."
    . "$Root\scripts\load-dotenv.ps1"
    $env:SPRING_FLYWAY_VALIDATE_ON_MIGRATE = "false"
    $apiJob = Start-Job -ScriptBlock {
        . (Join-Path $using:Root "scripts\load-dotenv.ps1")
        $env:SPRING_FLYWAY_VALIDATE_ON_MIGRATE = "false"
        Set-Location $using:Root\go-prepared-api
        & .\mvnw.cmd spring-boot:run 2>&1
    }
    Write-Host "Waiting for API (up to 90s)..."
    for ($i = 0; $i -lt 45; $i++) {
        Start-Sleep -Seconds 2
        if (Test-ApiReady) {
            $apiUp = $true
            Write-Host "API is ready." -ForegroundColor Green
            break
        }
    }
    if (-not $apiUp) {
        Write-Host "API did not start in time. Check: Receive-Job -Id $($apiJob.Id)" -ForegroundColor Red
        Write-Host "Or run manually: cd go-prepared-api; `$env:SPRING_FLYWAY_VALIDATE_ON_MIGRATE='false'; .\mvnw.cmd spring-boot:run"
    }
}

# 3. Flutter web (fixed port + OAuth from repo .env)
Write-Host "Starting Flutter web..."
. "$Root\scripts\load-dotenv.ps1"
$flutterArgs = Get-FlutterWebRunArgs
if ($flutterArgs.Count -gt 0) {
    Write-Host "Flutter web args from .env: $($flutterArgs -join ' ')" -ForegroundColor Cyan
}
Set-Location "$Root\go-prepared-app"
flutter run -d chrome @flutterArgs
