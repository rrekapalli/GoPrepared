# Patches Flutter web SDK for https://github.com/flutter/flutter/issues/184683
# (LateInitializationError on _handledContextLostEvent during hot restart / webglcontextlost).
# Safe to re-run; no-op once stable Flutter includes the fix.

$ErrorActionPreference = "Stop"

$needle = "late Completer<void>? _handledContextLostEvent;"
$replacement = "Completer<void>? _handledContextLostEvent;"

function Get-FlutterSdkRoot {
    $doctor = flutter doctor -v 2>&1 | Out-String
    if ($doctor -match 'on channel \S+ at (.+?)[\r\n]') {
        return $Matches[1].Trim()
    }
    $flutterCmd = (Get-Command flutter -ErrorAction Stop).Source
    return (Resolve-Path (Join-Path (Split-Path $flutterCmd -Parent) '..')).Path
}

function Patch-SurfaceFile {
    param([string]$Path)

    if (-not (Test-Path $Path)) {
        Write-Host "Skip (missing): $Path"
        return $false
    }

    $content = Get-Content -Path $Path -Raw
    if ($content -notmatch [regex]::Escape($needle)) {
        if ($content -match [regex]::Escape($replacement)) {
            Write-Host "Already patched: $Path"
            return $false
        }
        Write-Host "Skip (pattern not found): $Path"
        return $false
    }

    $updated = $content.Replace($needle, $replacement)
    Set-Content -Path $Path -Value $updated -NoNewline
    Write-Host "Patched: $Path"
    return $true
}

$sdkRoot = Get-FlutterSdkRoot
$webSdk = Join-Path $sdkRoot "bin\cache\flutter_web_sdk\lib"
$engineSdk = Join-Path $sdkRoot "engine\src\flutter\lib\web_ui\lib\src\engine"

$targets = @(
    (Join-Path $webSdk "_engine\engine\canvaskit\surface.dart"),
    (Join-Path $webSdk "_skwasm_impl\skwasm_impl\surface.dart"),
    (Join-Path $engineSdk "canvaskit\surface.dart"),
    (Join-Path $engineSdk "skwasm\skwasm_impl\surface.dart")
)

$patched = 0
foreach ($target in $targets) {
    if (Patch-SurfaceFile -Path $target) { $patched++ }
}

if ($patched -gt 0) {
    Write-Host ""
    Write-Host "Patched $patched Flutter web surface file(s)."
}

Write-Host ""
Write-Host "Stop any running 'flutter run -d chrome' and start fresh:"
Write-Host "  .\scripts\flutter-run-web.ps1"
Write-Host ""
Write-Host "Hot restart alone will NOT pick up engine patches."
