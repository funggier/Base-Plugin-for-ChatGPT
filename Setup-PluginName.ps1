[CmdletBinding()]
param(
    [string]$TunnelId,
    [string]$ApiKey,
    [string]$OrganizationId,
    [int]$HealthPort = 0,
    [switch]$Force,
    [switch]$FillMissing
)

$ErrorActionPreference = 'Stop'
$Root = $PSScriptRoot
$Helper = Join-Path $Root 'scripts\PluginNameSettings.ps1'
. $Helper

Write-Host ''
Write-Host '========================================'
Write-Host ' PluginName - Connection Setup'
Write-Host '========================================'
Write-Host ''

$existing = Get-PluginNameSettings -Root $Root
$existingApi = $null
try { $existingApi = Unprotect-PluginNameApiKey -Root $Root } catch {}

if ($existing -and -not $Force -and -not $FillMissing) {
    $answer = Read-Host 'Existing PluginName connection settings found. Reconfigure them? [y/N]'
    if ($answer -notmatch '^(?i)y(es)?$') {
        Write-Host 'Setup cancelled. Existing settings were not changed.'
        exit 0
    }
}

if ($FillMissing) {
    if ([string]::IsNullOrWhiteSpace($TunnelId) -and $existing -and $existing.tunnel_id) {
        $TunnelId = [string]$existing.tunnel_id
    }
    if ([string]::IsNullOrWhiteSpace($OrganizationId) -and $existing -and $existing.organization_id) {
        $OrganizationId = [string]$existing.organization_id
    }
    if ($HealthPort -eq 0 -and $existing -and $existing.health_port) {
        $HealthPort = [int]$existing.health_port
    }
    if ([string]::IsNullOrWhiteSpace($ApiKey) -and -not [string]::IsNullOrWhiteSpace($existingApi)) {
        $ApiKey = $existingApi
    }
}

if ([string]::IsNullOrWhiteSpace($TunnelId)) {
    do {
        $TunnelId = Read-Host '1/4 Tunnel ID (tunnel_...)'
    } while ([string]::IsNullOrWhiteSpace($TunnelId))
}
elseif ($FillMissing) {
    Write-Host "1/4 Tunnel ID: reuse $TunnelId"
}

if ([string]::IsNullOrWhiteSpace($ApiKey)) {
    Write-Host '2/4 Runtime API key'
    $secure = Read-Host '    API key (input hidden)' -AsSecureString
    $bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
    try { $ApiKey = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr) }
    finally { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr) }
    if ([string]::IsNullOrWhiteSpace($ApiKey)) { throw 'Runtime API key cannot be empty.' }
}
elseif ($FillMissing) {
    Write-Host '2/4 Runtime API key: reuse encrypted credential'
}

if ([string]::IsNullOrWhiteSpace($OrganizationId)) {
    do {
        $OrganizationId = Read-Host '3/4 Organization ID (org_... or org-...)'
    } while ([string]::IsNullOrWhiteSpace($OrganizationId))
}
elseif ($FillMissing) {
    Write-Host "3/4 Organization ID: reuse $OrganizationId"
}

if ($HealthPort -eq 0) {
    while ($true) {
        $raw = Read-Host '4/4 Local health port [18010]'
        $candidate = 0
        if ([string]::IsNullOrWhiteSpace($raw)) { $candidate = 18010 }
        elseif (-not [int]::TryParse($raw, [ref]$candidate)) {
            Write-Host '    Invalid port. Enter a number from 1024 to 65535.'
            continue
        }
        if ($candidate -lt 1024 -or $candidate -gt 65535) {
            Write-Host '    Port must be between 1024 and 65535.'
            continue
        }
        if (-not (Test-PluginNamePortAvailable -Port $candidate)) {
            Write-Host "    Port $candidate is already in use. Choose another port."
            continue
        }
        $HealthPort = $candidate
        break
    }
}
elseif ($HealthPort -lt 1024 -or $HealthPort -gt 65535) {
    throw 'HealthPort must be between 1024 and 65535.'
}
elseif ($FillMissing -and $existing -and [int]$existing.health_port -eq $HealthPort) {
    Write-Host "4/4 Local health port: reuse $HealthPort"
}
elseif (-not (Test-PluginNamePortAvailable -Port $HealthPort)) {
    throw "HealthPort $HealthPort is already in use."
}

try {
    $settingsPath = Save-PluginNameSettings -Root $Root -TunnelId $TunnelId -OrganizationId $OrganizationId -HealthPort $HealthPort
    $apiPath = Protect-PluginNameApiKey -Root $Root -ApiKey $ApiKey
    $profile = Write-PluginNameProfile -Root $Root

    Write-Host ''
    Write-Host 'Setup result: PASS'
    Write-Host "Tunnel ID: $TunnelId"
    Write-Host 'Runtime API key: configured (encrypted with Windows DPAPI)'
    Write-Host "Organization ID: $OrganizationId"
    Write-Host "Health port: $HealthPort"
    Write-Host "Generated profile: $profile"
    Write-Host ''
    Write-Host 'Saved values are reused automatically until you explicitly clear them.'
    Write-Host 'Next: run Start-PluginName.cmd'
}
finally {
    Remove-Variable ApiKey, existingApi -ErrorAction SilentlyContinue
}
