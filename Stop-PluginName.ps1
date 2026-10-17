[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$Root = $PSScriptRoot
. (Join-Path $Root 'scripts\PluginNameSettings.ps1')
$p = Get-PluginNamePaths -Root $Root

Write-Host ''
Write-Host '========================================'
Write-Host ' PluginName - Stop'
Write-Host '========================================'

$ids = @()
foreach ($file in @($p.LauncherPid,$p.TunnelPid)) {
    if (Test-Path -LiteralPath $file) {
        $raw=(Get-Content -LiteralPath $file -Raw).Trim()
        $value=0
        if ([int]::TryParse($raw,[ref]$value)) { $ids += $value }
    }
}
$ids = $ids | Sort-Object -Unique -Descending

foreach ($id in $ids) {
    $proc=Get-Process -Id $id -ErrorAction SilentlyContinue
    if ($proc) {
        Write-Host "Stopping PID $id..."
        Stop-Process -Id $id -Force -ErrorAction SilentlyContinue
    }
}

Remove-Item -LiteralPath $p.LauncherPid,$p.TunnelPid,$p.HealthUrl -Force -ErrorAction SilentlyContinue
Write-Host 'PluginName stopped.'
