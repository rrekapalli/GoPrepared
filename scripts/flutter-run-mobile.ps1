# Run Flutter on a connected phone/emulator with API URL suited for native (not localhost).
param(
    [string]$Device,
    [switch]$Emulator,
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$FlutterArgs
)

$ErrorActionPreference = "Stop"
$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$appDir = Join-Path $repoRoot "go-prepared-app"

. (Join-Path $PSScriptRoot "load-dotenv.ps1")
$dartDefines = Get-FlutterMobileRunArgs
if ($Emulator) {
    $dartDefines = @($dartDefines | Where-Object { $_ -notmatch '^--dart-define=API_BASE_URL=' })
    $dartDefines += '--dart-define=ANDROID_USE_EMULATOR_HOST=true'
    $dartDefines += '--dart-define=API_BASE_URL=http://10.0.2.2:8080/api/v1'
}
if ($dartDefines.Count -gt 0) {
    Write-Host "Flutter mobile dart-defines: $($dartDefines -join ' ')" -ForegroundColor Cyan
}

Push-Location $appDir
try {
    $allArgs = @($dartDefines) + @($FlutterArgs)
    if ($Device) {
        flutter run -d $Device @allArgs
    } else {
        flutter run @allArgs
    }
} finally {
    Pop-Location
}
