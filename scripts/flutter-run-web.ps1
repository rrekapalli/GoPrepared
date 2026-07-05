# Patches Flutter web context-lost bug, clears stale web build artifacts, runs Chrome.
param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$FlutterArgs
)

$ErrorActionPreference = "Stop"
$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$appDir = Join-Path $repoRoot "go-prepared-app"

. (Join-Path $PSScriptRoot "load-dotenv.ps1")
$flutterArgs = Get-FlutterWebRunArgs
if ($flutterArgs.Count -gt 0) {
    Write-Host "Flutter web args from .env: $($flutterArgs -join ' ')" -ForegroundColor Cyan
}

& (Join-Path $PSScriptRoot "patch-flutter-web-context-lost.ps1")

Push-Location $appDir
try {
    flutter clean | Out-Host
    flutter pub get | Out-Host
    $allArgs = @($flutterArgs) + @($FlutterArgs)
    flutter run -d chrome @allArgs
} finally {
    Pop-Location
}
