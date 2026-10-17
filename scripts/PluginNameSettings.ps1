$script:PluginNameSettingsVersion = 1

function Get-PluginNamePaths {
    param([string]$Root)
    $LocalSecrets = Join-Path $Root 'local-secrets'
    $Runtime = Join-Path $Root 'runtime'
    $Logs = Join-Path $Root 'logs'
    [pscustomobject]@{
        Root = $Root
        LocalSecrets = $LocalSecrets
        Runtime = $Runtime
        Logs = $Logs
        SettingsFile = Join-Path $LocalSecrets 'PluginName-settings.json'
        ApiKeyFile = Join-Path $LocalSecrets 'PluginName-api-key.dpapi'
        ProfileFile = Join-Path $Root 'mcp-conf.yaml'
        LauncherPid = Join-Path $Runtime 'launcher.pid'
        TunnelPid = Join-Path $Runtime 'tunnel-client.pid'
        HealthUrl = Join-Path $Runtime 'health-url.txt'
    }
}

function Test-PluginNamePortAvailable {
    param([Parameter(Mandatory=$true)][int]$Port)
    try {
        $listener = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Loopback, $Port)
        $listener.Start()
        $listener.Stop()
        return $true
    }
    catch {
        try { if ($listener) { $listener.Stop() } } catch {}
        return $false
    }
}

function Protect-PluginNameApiKey {
    param(
        [Parameter(Mandatory=$true)][string]$Root,
        [Parameter(Mandatory=$true)][string]$ApiKey
    )
    $p = Get-PluginNamePaths -Root $Root
    New-Item -ItemType Directory -Force -Path $p.LocalSecrets | Out-Null
    $secure = ConvertTo-SecureString $ApiKey -AsPlainText -Force
    $encrypted = ConvertFrom-SecureString $secure
    Set-Content -LiteralPath $p.ApiKeyFile -Value $encrypted -Encoding UTF8
    return $p.ApiKeyFile
}

function Unprotect-PluginNameApiKey {
    param([Parameter(Mandatory=$true)][string]$Root)
    $p = Get-PluginNamePaths -Root $Root
    if (-not (Test-Path -LiteralPath $p.ApiKeyFile -PathType Leaf)) { return $null }
    $encrypted = (Get-Content -LiteralPath $p.ApiKeyFile -Raw).Trim()
    $secure = ConvertTo-SecureString $encrypted
    $bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
    try { return [Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr) }
    finally { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr) }
}

function Get-PluginNameSettings {
    param([Parameter(Mandatory=$true)][string]$Root)
    $p = Get-PluginNamePaths -Root $Root
    if (-not (Test-Path -LiteralPath $p.SettingsFile -PathType Leaf)) { return $null }
    return Get-Content -LiteralPath $p.SettingsFile -Raw | ConvertFrom-Json
}

function Save-PluginNameSettings {
    param(
        [Parameter(Mandatory=$true)][string]$Root,
        [Parameter(Mandatory=$true)][string]$TunnelId,
        [Parameter(Mandatory=$true)][string]$OrganizationId,
        [Parameter(Mandatory=$true)][int]$HealthPort
    )
    $p = Get-PluginNamePaths -Root $Root
    New-Item -ItemType Directory -Force -Path $p.LocalSecrets | Out-Null
    $obj = [ordered]@{
        version = $script:PluginNameSettingsVersion
        tunnel_id = $TunnelId
        organization_id = $OrganizationId
        health_port = $HealthPort
        updated_at = (Get-Date).ToString('o')
    }
    $obj | ConvertTo-Json | Set-Content -LiteralPath $p.SettingsFile -Encoding UTF8
    return $p.SettingsFile
}

function Write-PluginNameProfile {
    param([Parameter(Mandatory=$true)][string]$Root)
    $settings = Get-PluginNameSettings -Root $Root
    if (-not $settings) { throw 'PluginName settings are not configured. Run Setup-PluginName.cmd first.' }
    $p = Get-PluginNamePaths -Root $Root
    New-Item -ItemType Directory -Force -Path $p.Runtime | Out-Null
    $yaml = @"
config_version: 1

control_plane:
  base_url: "https://api.openai.com"
  tunnel_id: "$($settings.tunnel_id)"
  api_key: "env:CONTROL_PLANE_API_KEY"

health:
  listen_addr: "127.0.0.1:$($settings.health_port)"
  url_file: "runtime/health-url.txt"

admin_ui:
  open_browser: false

log:
  level: info
  format: json

mcp:
  commands:
    - channel: main
      command: 'node "PluginName.mjs"'
"@
    Set-Content -LiteralPath $p.ProfileFile -Value $yaml -Encoding UTF8
    return $p.ProfileFile
}
