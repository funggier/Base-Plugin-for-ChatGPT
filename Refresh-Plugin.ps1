[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$Root = $PSScriptRoot
. (Join-Path $Root 'scripts\PluginSettings.ps1')
$p = Get-PluginPaths -Root $Root

Write-Host ''
Write-Host '========================================'
Write-Host ' Plugin - Offline Refresh'
Write-Host '========================================'
Write-Host ''

if (Test-Path -LiteralPath $p.LauncherPid) {
    $raw = (Get-Content -LiteralPath $p.LauncherPid -Raw).Trim()
    $pidValue = 0
    if ([int]::TryParse($raw,[ref]$pidValue)) {
        $proc = Get-Process -Id $pidValue -ErrorAction SilentlyContinue
        if ($proc) {
            throw "Plugin is still running (PID $pidValue). Run Stop-Plugin.cmd first."
        }
    }
}

$result = Clear-PluginGeneratedState -Root $Root

Write-Host 'Generated state cleared:'
Write-Host '  - runtime/'
Write-Host '  - logs/'
Write-Host ''
Write-Host 'Preserved:'
Write-Host '  - local-secrets/ (settings + DPAPI credential)'
Write-Host '  - mcp-conf.yaml'
Write-Host '  - Plugin-runtime/ (plugin-owned drivers/binaries/cache)'
Write-Host '  - source files and dependencies'
Write-Host ''
Write-Host "Persistent runtime: $($result.persistent_runtime)"
Write-Host 'Refresh result: PASS'
