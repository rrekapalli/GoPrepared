$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$contentDir = Join-Path $root "go-prepared-content\output"
$env:PGPASSWORD = if ($env:POSTGRES_PASSWORD) { $env:POSTGRES_PASSWORD } else { "goprepared" }
$host_ = if ($env:POSTGRES_HOST) { $env:POSTGRES_HOST } else { "localhost" }
$port = if ($env:POSTGRES_PORT) { $env:POSTGRES_PORT } else { "5432" }
$db = if ($env:POSTGRES_DB) { $env:POSTGRES_DB } else { "goprepared" }
$user = if ($env:POSTGRES_USER) { $env:POSTGRES_USER } else { "goprepared" }

if (-not (Test-Path $contentDir)) {
    Write-Host "Running generate-content first..."
    & "$PSScriptRoot\generate-content.ps1"
}

$templates = Join-Path $contentDir "journey-templates"
Get-ChildItem $templates -Filter *.json | ForEach-Object {
    $json = Get-Content $_.FullName -Raw
    $key = $_.BaseName
    $escaped = $json.Replace("'", "''")
    $sql = @"
INSERT INTO content_templates (template_key, journey_type, journey_subtype, activity, location, payload)
VALUES ('$key',
  (SELECT payload->'classification'->>'journeyType' FROM (SELECT '$escaped'::jsonb AS payload) t),
  (SELECT payload->'classification'->>'journeySubtype' FROM (SELECT '$escaped'::jsonb AS payload) t),
  (SELECT payload->'classification'->>'activity' FROM (SELECT '$escaped'::jsonb AS payload) t),
  (SELECT payload->'classification'->>'location' FROM (SELECT '$escaped'::jsonb AS payload) t),
  '$escaped'::jsonb)
ON CONFLICT (template_key) DO UPDATE SET payload = EXCLUDED.payload;
"@
    psql -h $host_ -p $port -U $user -d $db -c $sql
}

$graph = Join-Path $contentDir "knowledge\graph.json"
if (Test-Path $graph) {
    $g = Get-Content $graph -Raw | ConvertFrom-Json
    foreach ($node in $g.nodes) {
        $name = $node.name.Replace("'", "''")
        $desc = ($node.description ?? "").Replace("'", "''")
        $type = $node.nodeType
        psql -h $host_ -p $port -U $user -d $db -c "INSERT INTO knowledge_nodes (node_type, name, description) VALUES ('$type', '$name', '$desc') ON CONFLICT (node_type, name) DO NOTHING;"
    }
}

$community = Join-Path $contentDir "community\featured.json"
if (Test-Path $community) {
    $items = Get-Content $community -Raw | ConvertFrom-Json
    foreach ($item in $items) {
        $title = $item.title.Replace("'", "''")
        $content = $item.content.Replace("'", "''")
        $type = $item.insightType
        $ctx = ($item.journeyContext ?? "").Replace("'", "''")
        $sev = $item.severity
        psql -h $host_ -p $port -U $user -d $db -c "INSERT INTO community_insights (insight_type, title, content, journey_context, severity, votes, status) VALUES ('$type', '$title', '$content', '$ctx', $(if ($sev) { "'$sev'" } else { "NULL" }), 126, 'ACTIVE');"
    }
}

Write-Host "Content import complete."
