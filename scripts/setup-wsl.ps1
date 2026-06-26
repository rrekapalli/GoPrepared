# Bootstrap Ubuntu 24.04 WSL for GoPrepared (same pattern as MoneyTree / purana-samhitha).
# Run from repo root: powershell -File scripts/setup-wsl.ps1

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $PSScriptRoot
$Distro = "Ubuntu-24.04"

function Test-WslDistro([string]$Name) {
    $list = wsl -l -v 2>&1 | Out-String
    return $list -match [regex]::Escape($Name)
}

Write-Host "=== GoPrepared WSL setup ($Distro) ==="

if (-not (Get-Command wsl -ErrorAction SilentlyContinue)) {
    throw "WSL is not installed. Run: wsl --install -d Ubuntu-24.04"
}

if (-not (Test-WslDistro $Distro)) {
    Write-Host "Installing $Distro..."
    wsl --install -d $Distro --no-launch
}

Write-Host "Setting default WSL distro to $Distro..."
wsl --set-default $Distro

$wslRoot = (wsl -d $Distro wslpath -u $Root).Trim()
Write-Host "Running prepare-dev-machine.sh in $Distro ($wslRoot)..."
wsl -d $Distro bash -lc "cd $(wsl -d $Distro wslpath -u $Root) && bash deployment/prepare-dev-machine.sh"

Write-Host ""
Write-Host "Done. Use Cursor terminal profile 'Ubuntu-24.04' or: wsl -d $Distro"
Write-Host "Deploy: wsl -d $Distro bash -lc 'cd $wslRoot && ./deploy.sh'"
