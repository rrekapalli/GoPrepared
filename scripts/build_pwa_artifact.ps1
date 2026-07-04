# Build GoPrepared PWA and zip for deployment/artifacts/pwa-dist.zip
# Run from repo root on Windows (PowerShell), or invoked from WSL deploy.

$ErrorActionPreference = "Stop"

$Root = Split-Path -Parent $PSScriptRoot
$AppDir = Join-Path $Root "go-prepared-app"
$ArtifactsDir = Join-Path $Root "deployment\artifacts"
$BuildDir = Join-Path $AppDir "build\web"
$ZipPath = Join-Path $ArtifactsDir "pwa-dist.zip"

# Load GOPREPARED_HOST from .env for production API URL
$EnvFile = Join-Path $Root ".env"
$ApiBaseUrl = "http://localhost:8080/api/v1"
if (Test-Path $EnvFile) {
    Get-Content $EnvFile | ForEach-Object {
        if ($_ -match '^\s*GOPREPARED_HOST\s*=\s*(.+)\s*$') {
            $gopreparedHost = $Matches[1].Trim().Trim('"')
            if ($gopreparedHost -notmatch '^https?://') { $gopreparedHost = "http://$gopreparedHost" }
            $ApiBaseUrl = "$gopreparedHost/api/v1"
        }
    }
}

Push-Location $AppDir
try {
    flutter pub get
    flutter build web --release `
        --dart-define="API_BASE_URL=$ApiBaseUrl"
}
finally {
    Pop-Location
}

if (-not (Test-Path (Join-Path $BuildDir "index.html"))) {
    throw "Flutter web build failed: index.html missing in $BuildDir"
}

$VersionJson = Join-Path $BuildDir "version.json"
$BuildIdFile = Join-Path $BuildDir ".last_build_id"
if ((Test-Path $VersionJson) -and (Test-Path $BuildIdFile)) {
    $buildId = (Get-Content $BuildIdFile -Raw).Trim()
    $version = Get-Content $VersionJson -Raw | ConvertFrom-Json
    $version | Add-Member -NotePropertyName "build_id" -NotePropertyValue $buildId -Force
    ($version | ConvertTo-Json -Compress) + "`n" | Set-Content $VersionJson -NoNewline
}

New-Item -ItemType Directory -Force -Path $ArtifactsDir | Out-Null
if (Test-Path $ZipPath) { Remove-Item $ZipPath -Force }

function New-UnixZipArchive {
    param(
        [Parameter(Mandatory)][string]$SourceDir,
        [Parameter(Mandatory)][string]$DestinationPath
    )
    Add-Type -AssemblyName System.IO.Compression
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $sourceFull = (Resolve-Path $SourceDir).Path
    if ($sourceFull.EndsWith('\')) {
        $sourceFull = $sourceFull.TrimEnd('\')
    }
    $archive = [System.IO.Compression.ZipFile]::Open(
        $DestinationPath,
        [System.IO.Compression.ZipArchiveMode]::Create)
    try {
        Get-ChildItem -Path $sourceFull -Recurse -File | ForEach-Object {
            $relative = $_.FullName.Substring($sourceFull.Length + 1).Replace('\', '/')
            [void][System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile(
                $archive, $_.FullName, $relative)
        }
    }
    finally {
        $archive.Dispose()
    }
}

New-UnixZipArchive -SourceDir $BuildDir -DestinationPath $ZipPath
Write-Host "PWA zip: $ZipPath (API_BASE_URL=$ApiBaseUrl)"
