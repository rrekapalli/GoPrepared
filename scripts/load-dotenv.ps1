# Load key=value pairs from repo-root .env into the current process environment.
param(
    [string]$EnvFile = (Join-Path (Split-Path -Parent $PSScriptRoot) ".env")
)

if (-not (Test-Path $EnvFile)) {
    return
}

Get-Content $EnvFile | ForEach-Object {
    $line = $_.Trim()
    if ($line -eq '' -or $line.StartsWith('#')) { return }
    $eq = $line.IndexOf('=')
    if ($eq -lt 1) { return }
    $name = $line.Substring(0, $eq).Trim()
    $value = $line.Substring($eq + 1).Trim()
    if ($name) {
        Set-Item -Path "env:$name" -Value $value
    }
}

function Get-FlutterOAuthDartDefines {
    $defines = @()
    if ($env:GOOGLE_CLIENT_ID -and $env:GOOGLE_CLIENT_ID -notmatch '^your-') {
        $defines += "--dart-define=GOOGLE_CLIENT_ID=$($env:GOOGLE_CLIENT_ID)"
    }
    if ($env:MICROSOFT_CLIENT_ID -and $env:MICROSOFT_CLIENT_ID -notmatch '^your-') {
        $defines += "--dart-define=MICROSOFT_CLIENT_ID=$($env:MICROSOFT_CLIENT_ID)"
    }
    if ($env:MICROSOFT_TENANT_ID) {
        $defines += "--dart-define=MICROSOFT_TENANT_ID=$($env:MICROSOFT_TENANT_ID)"
    }
    if ($env:API_BASE_URL) {
        $defines += "--dart-define=API_BASE_URL=$($env:API_BASE_URL)"
    }
    if ($env:GOPREPARED_HOST) {
        $defines += "--dart-define=GOPREPARED_HOST=$($env:GOPREPARED_HOST)"
    }
    if ($env:GOPREPARED_AUTH_DEV_ENABLED -eq 'false') {
        $defines += '--dart-define=DEV_AUTH_ENABLED=false'
    }
    if ($env:FLUTTER_WEB_PORT) {
        $defines += "--dart-define=MICROSOFT_REDIRECT_URI=http://localhost:$($env:FLUTTER_WEB_PORT)/auth"
    }
    return $defines
}

function Get-FlutterMobileRunArgs {
    $defines = @(Get-FlutterOAuthDartDefines)

    # Physical devices cannot reach localhost on the dev PC — prefer MOBILE_API_BASE_URL or production host.
    $mobileApiUrl = $env:MOBILE_API_BASE_URL
    if (-not $mobileApiUrl -and $env:GOPREPARED_HOST) {
        $mobileApiUrl = "https://$($env:GOPREPARED_HOST)/api/v1"
    }

    if ($mobileApiUrl) {
        $defines = @($defines | Where-Object { $_ -notmatch '^--dart-define=API_BASE_URL=' })
        $defines += "--dart-define=API_BASE_URL=$mobileApiUrl"
    }

    return $defines
}

function Get-FlutterWebRunArgs {
    $args = @()
    if ($env:FLUTTER_WEB_PORT) {
        $args += "--web-port=$($env:FLUTTER_WEB_PORT)"
    }
    $args += Get-FlutterOAuthDartDefines
    return $args
}
