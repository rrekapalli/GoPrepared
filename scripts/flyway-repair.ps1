# Repairs Flyway checksum mismatches after migration file edits (dev only).
# Loads POSTGRES_* from repo .env when present.
$ErrorActionPreference = "Stop"
$root = Split-Path $PSScriptRoot -Parent
$envFile = Join-Path $root ".env"
if (Test-Path $envFile) {
    Get-Content $envFile | ForEach-Object {
        if ($_ -match '^\s*([^#=]+)=(.*)$') {
            $name = $matches[1].Trim()
            $value = $matches[2].Trim()
            Set-Item -Path "Env:$name" -Value $value
        }
    }
}

$host_ = if ($env:POSTGRES_HOST) { $env:POSTGRES_HOST } else { "localhost" }
$port = if ($env:POSTGRES_PORT) { $env:POSTGRES_PORT } else { "5432" }
$db = if ($env:POSTGRES_DB) { $env:POSTGRES_DB } else { "goprepared" }
$user = if ($env:POSTGRES_USER) { $env:POSTGRES_USER } else { "goprepared" }
$pass = if ($env:POSTGRES_PASSWORD) { $env:POSTGRES_PASSWORD } else { "goprepared" }

Push-Location (Join-Path $root "go-prepared-api")
try {
    .\mvnw.cmd -q org.flywaydb:flyway-maven-plugin:10.20.1:repair `
        "-Dflyway.url=jdbc:postgresql://${host_}:${port}/${db}" `
        "-Dflyway.user=$user" `
        "-Dflyway.password=$pass" `
        "-Dflyway.locations=classpath:db/migration"
    Write-Host "Flyway repair complete for $host_/$db"
} finally {
    Pop-Location
}
