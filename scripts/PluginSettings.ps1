$script:PluginSettingsVersion = 1

function Get-PluginPaths {
    param([string]$Root)
    $LocalSecrets = Join-Path $Root 'local-secrets'
    $Runtime = Join-Path $Root 'runtime'
    $PersistentRuntime = Join-Path $Root 'Plugin-runtime'
    $Logs = Join-Path $Root 'logs'
    [pscustomobject]@{
        Root = $Root
        LocalSecrets = $LocalSecrets
        Runtime = $Runtime
        PersistentRuntime = $PersistentRuntime
        Logs = $Logs
        SettingsFile = Join-Path $LocalSecrets 'Plugin-settings.json'
        ApiKeyFile = Join-Path $LocalSecrets 'Plugin-api-key.dpapi'
        ProfileFile = Join-Path $Root 'mcp-conf.yaml'
        LauncherPid = Join-Path $Runtime 'launcher.pid'
        TunnelPid = Join-Path $Runtime 'tunnel-client.pid'
        HealthUrl = Join-Path $Runtime 'health-url.txt'
    }
}

function Test-PluginPortAvailable {
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

function Protect-PluginApiKey {
    param(
        [Parameter(Mandatory=$true)][string]$Root,
        [Parameter(Mandatory=$true)][string]$ApiKey
    )
    $p = Get-PluginPaths -Root $Root
    New-Item -ItemType Directory -Force -Path $p.LocalSecrets | Out-Null
    $secure = ConvertTo-SecureString $ApiKey -AsPlainText -Force
    $encrypted = ConvertFrom-SecureString $secure
    Set-Content -LiteralPath $p.ApiKeyFile -Value $encrypted -Encoding UTF8
    return $p.ApiKeyFile
}

function Unprotect-PluginApiKey {
    param([Parameter(Mandatory=$true)][string]$Root)
    $p = Get-PluginPaths -Root $Root
    if (-not (Test-Path -LiteralPath $p.ApiKeyFile -PathType Leaf)) { return $null }
    $encrypted = (Get-Content -LiteralPath $p.ApiKeyFile -Raw).Trim()
    $secure = ConvertTo-SecureString $encrypted
    $bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
    try { return [Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr) }
    finally { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr) }
}

function Get-PluginSettings {
    param([Parameter(Mandatory=$true)][string]$Root)
    $p = Get-PluginPaths -Root $Root
    if (-not (Test-Path -LiteralPath $p.SettingsFile -PathType Leaf)) { return $null }
    return Get-Content -LiteralPath $p.SettingsFile -Raw | ConvertFrom-Json
}

function Save-PluginSettings {
    param(
        [Parameter(Mandatory=$true)][string]$Root,
        [Parameter(Mandatory=$true)][string]$TunnelId,
        [Parameter(Mandatory=$true)][string]$OrganizationId,
        [Parameter(Mandatory=$true)][int]$HealthPort
    )
    $p = Get-PluginPaths -Root $Root
    New-Item -ItemType Directory -Force -Path $p.LocalSecrets | Out-Null
    $obj = [ordered]@{
        version = $script:PluginSettingsVersion
        tunnel_id = $TunnelId
        organization_id = $OrganizationId
        health_port = $HealthPort
        updated_at = (Get-Date).ToString('o')
    }
    $obj | ConvertTo-Json | Set-Content -LiteralPath $p.SettingsFile -Encoding UTF8
    return $p.SettingsFile
}

function Write-PluginProfile {
    param([Parameter(Mandatory=$true)][string]$Root)
    $settings = Get-PluginSettings -Root $Root
    if (-not $settings) { throw 'Plugin settings are not configured. Run Setup-Plugin.cmd first.' }
    $p = Get-PluginPaths -Root $Root
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
      command: 'node "Plugin.mjs"'
"@
    Set-Content -LiteralPath $p.ProfileFile -Value $yaml -Encoding UTF8
    return $p.ProfileFile
}

function Clear-PluginGeneratedState {
    param([Parameter(Mandatory=$true)][string]$Root)
    $p = Get-PluginPaths -Root $Root

    if (Test-Path -LiteralPath $p.Runtime) {
        Remove-Item -LiteralPath $p.Runtime -Recurse -Force -ErrorAction Stop
    }
    if (Test-Path -LiteralPath $p.Logs) {
        Remove-Item -LiteralPath $p.Logs -Recurse -Force -ErrorAction Stop
    }

    New-Item -ItemType Directory -Force -Path $p.Runtime,$p.Logs,$p.PersistentRuntime | Out-Null

    [pscustomobject]@{
        runtime_cleared = $true
        logs_cleared = $true
        persistent_runtime_preserved = $true
        persistent_runtime = $p.PersistentRuntime
    }
}
