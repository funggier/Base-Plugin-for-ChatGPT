[CmdletBinding()]
param([switch]$NonInteractive)

$ErrorActionPreference = 'Stop'
$Root = $PSScriptRoot
$Client = Join-Path $Root 'tunnel-client.exe'
$Helper = Join-Path $Root 'scripts\PluginNameSettings.ps1'
. $Helper
$p = Get-PluginNamePaths -Root $Root

Write-Host ''
Write-Host '========================================'
Write-Host ' PluginName - Start'
Write-Host '========================================'

if (-not (Test-Path -LiteralPath $Client -PathType Leaf)) {
    throw "Missing tunnel-client.exe in $Root"
}
if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
    throw 'Node.js was not found.'
}

$settings = Get-PluginNameSettings -Root $Root
$apiKey = $null
try { $apiKey = Unprotect-PluginNameApiKey -Root $Root } catch {}

if (-not $settings -or [string]::IsNullOrWhiteSpace($apiKey)) {
    if ($NonInteractive) {
        throw 'FIRST_RUN_REQUIRED: A cleared or missing connection value must be configured before non-interactive start.'
    }

    Write-Host 'One or more connection values are missing.'
    Write-Host 'Only missing values will be requested; saved values will be reused.'
    & (Join-Path $Root 'Setup-PluginName.ps1') -FillMissing
    if ($LASTEXITCODE -ne 0) { throw "Setup failed (exit $LASTEXITCODE)." }

    $settings = Get-PluginNameSettings -Root $Root
    $apiKey = Unprotect-PluginNameApiKey -Root $Root
}

if (-not $settings -or [string]::IsNullOrWhiteSpace($apiKey)) {
    throw 'Connection setup is incomplete.'
}

if (Test-Path -LiteralPath $p.LauncherPid) {
    $existingPid = (Get-Content -LiteralPath $p.LauncherPid -Raw).Trim()
    $existing = Get-Process -Id $existingPid -ErrorAction SilentlyContinue
    if ($existing) {
        Write-Host "PluginName is already running (PID $existingPid)."
        Write-Host 'Saved connection settings were reused; no setup was required.'
        exit 0
    }
    Remove-Item -LiteralPath $p.LauncherPid -Force -ErrorAction SilentlyContinue
}

if (-not (Test-PluginNamePortAvailable -Port ([int]$settings.health_port))) {
    throw "Configured health port $($settings.health_port) is in use. Run Setup-PluginName.cmd to choose another port."
}

New-Item -ItemType Directory -Force -Path $p.Runtime,$p.Logs | Out-Null
$profile = Write-PluginNameProfile -Root $Root

$previousKey = [Environment]::GetEnvironmentVariable('CONTROL_PLANE_API_KEY','Process')
$previousOrg = [Environment]::GetEnvironmentVariable('CONTROL_PLANE_ORGANIZATION_ID','Process')

try {
    $env:CONTROL_PLANE_API_KEY = $apiKey
    $env:CONTROL_PLANE_ORGANIZATION_ID = [string]$settings.organization_id

    Write-Host "Tunnel ID: $($settings.tunnel_id)"
    Write-Host "Organization ID: $($settings.organization_id)"
    Write-Host "Health port: $($settings.health_port)"
    Write-Host 'Connection values: reused from saved local settings'
    Write-Host 'Checking configuration...'

    Push-Location -LiteralPath $Root
    try {
        & $Client doctor --profile-file $profile --control-plane.organization-id $settings.organization_id --pid.file $p.TunnelPid --explain 2>&1 | Tee-Object -FilePath (Join-Path $p.Logs 'doctor-latest.log')
        if ($LASTEXITCODE -ne 0) { throw "Configuration check failed (exit $LASTEXITCODE)." }

        $stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
        $args = @('run','--profile-file',$profile,'--control-plane.organization-id',$settings.organization_id,'--pid.file',$p.TunnelPid)
        $proc = Start-Process -FilePath $Client -WorkingDirectory $Root -ArgumentList $args -WindowStyle Hidden -PassThru -RedirectStandardOutput (Join-Path $p.Logs "tunnel-$stamp.out.log") -RedirectStandardError (Join-Path $p.Logs "tunnel-$stamp.err.log")
        Set-Content -LiteralPath $p.LauncherPid -Value $proc.Id -NoNewline
    }
    finally { Pop-Location }

    Start-Sleep -Seconds 2
    if (-not (Get-Process -Id $proc.Id -ErrorAction SilentlyContinue)) {
        Remove-Item -LiteralPath $p.LauncherPid -Force -ErrorAction SilentlyContinue
        throw 'PluginName exited during startup. Check logs.'
    }

    Write-Host ''
    Write-Host "PluginName started (PID $($proc.Id))."
    Write-Host 'Run Status-PluginName.cmd to check readiness.'
}
finally {
    if ($null -eq $previousKey) { Remove-Item Env:CONTROL_PLANE_API_KEY -ErrorAction SilentlyContinue } else { $env:CONTROL_PLANE_API_KEY=$previousKey }
    if ($null -eq $previousOrg) { Remove-Item Env:CONTROL_PLANE_ORGANIZATION_ID -ErrorAction SilentlyContinue } else { $env:CONTROL_PLANE_ORGANIZATION_ID=$previousOrg }
    Remove-Variable apiKey -ErrorAction SilentlyContinue
}
