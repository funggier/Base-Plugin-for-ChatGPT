[CmdletBinding()]
param(
    [ValidateSet('credential','connection','all')]
    [string]$Mode
)

$ErrorActionPreference = 'Stop'
$Root = $PSScriptRoot
. (Join-Path $Root 'scripts\PluginNameSettings.ps1')
$p = Get-PluginNamePaths -Root $Root

Write-Host ''
Write-Host '========================================'
Write-Host ' PluginName - Clear Settings'
Write-Host '========================================'
Write-Host ''

if ([string]::IsNullOrWhiteSpace($Mode)) {
    Write-Host '1. Clear API key only'
    Write-Host '2. Clear connection settings (Tunnel ID / Organization / Port)'
    Write-Host '3. Clear ALL local PluginName settings'
    Write-Host '0. Cancel'
    $choice = Read-Host 'Select'
    switch ($choice) {
        '1' { $Mode='credential' }
        '2' { $Mode='connection' }
        '3' { $Mode='all' }
        default { Write-Host 'Cancelled.'; exit 0 }
    }
}

$answer = Read-Host "Confirm clear mode '$Mode'? [y/N]"
if ($answer -notmatch '^(?i)y(es)?$') {
    Write-Host 'Clear cancelled.'
    exit 0
}

if ($Mode -in @('credential','all')) {
    Remove-Item -LiteralPath $p.ApiKeyFile -Force -ErrorAction SilentlyContinue
    Write-Host 'API key file: cleared'
}
if ($Mode -in @('connection','all')) {
    Remove-Item -LiteralPath $p.SettingsFile,$p.ProfileFile -Force -ErrorAction SilentlyContinue
    Write-Host 'Connection settings/profile: cleared'
}
if ($Mode -eq 'all') {
    Remove-Item -LiteralPath $p.Runtime -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath $p.Logs -Recurse -Force -ErrorAction SilentlyContinue
    New-Item -ItemType Directory -Force -Path $p.Runtime | Out-Null
    Write-Host 'Runtime/log state: cleared'
}

Write-Host 'Clear result: PASS'
