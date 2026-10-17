[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$Root = $PSScriptRoot
. (Join-Path $Root 'scripts\PluginNameSettings.ps1')
$p = Get-PluginNamePaths -Root $Root
$settings = Get-PluginNameSettings -Root $Root

Write-Host ''
Write-Host '========================================'
Write-Host ' PluginName - Status'
Write-Host '========================================'

if (-not $settings) {
    Write-Host 'Connection settings: not configured'
    Write-Host 'Run Setup-PluginName.cmd'
    exit 1
}

Write-Host "Tunnel ID: $($settings.tunnel_id)"
Write-Host "Organization ID: $($settings.organization_id)"
Write-Host "Health port: $($settings.health_port)"
Write-Host "API key: $(if (Test-Path -LiteralPath $p.ApiKeyFile) { 'configured (encrypted)' } else { 'not configured' })"

if (-not (Test-Path -LiteralPath $p.LauncherPid)) {
    Write-Host 'Process: stopped'
    exit 1
}

$pidText = (Get-Content -LiteralPath $p.LauncherPid -Raw).Trim()
$proc = Get-Process -Id $pidText -ErrorAction SilentlyContinue
if (-not $proc) {
    Write-Host "Process: stopped (stale PID $pidText)"
    exit 1
}

Write-Host "Process: running (PID $pidText)"

if (-not (Test-Path -LiteralPath $p.HealthUrl)) {
    Write-Host 'Health URL: unavailable'
    exit 2
}
$base = (Get-Content -LiteralPath $p.HealthUrl -Raw).Trim().TrimEnd('/')

try {
    $live = Invoke-WebRequest -UseBasicParsing -TimeoutSec 5 -Uri "$base/healthz"
    Write-Host "Liveness: $($live.StatusCode) $($live.Content)"
}
catch {
    Write-Host "Liveness: FAIL - $($_.Exception.Message)"
    exit 2
}

try {
    $ready = Invoke-WebRequest -UseBasicParsing -TimeoutSec 5 -Uri "$base/readyz"
    Write-Host "Startup readiness: $($ready.StatusCode) $($ready.Content)"
}
catch {
    Write-Host "Startup readiness: FAIL - $($_.Exception.Message)"
    exit 2
}

Write-Host "UI: $base/ui"
exit 0
