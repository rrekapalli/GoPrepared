# Patches Flutter web context-lost bug, clears stale web build artifacts, runs Chrome.
param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$FlutterArgs
)

$ErrorActionPreference = "Stop"
$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$appDir = Join-Path $repoRoot "go-prepared-app"

& (Join-Path $PSScriptRoot "patch-flutter-web-context-lost.ps1")

Push-Location $appDir
try {
    flutter clean | Out-Host
    flutter pub get | Out-Host
    if ($FlutterArgs.Count -gt 0) {
        flutter run -d chrome @FlutterArgs
    } else {
        flutter run -d chrome
    }
} finally {
    Pop-Location
}
