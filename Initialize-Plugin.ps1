[CmdletBinding()]
param(
    [string]$Name,
    [switch]$Force,
    [switch]$Preview
)

$ErrorActionPreference = 'Stop'
$Root = $PSScriptRoot
$TemplateToken = ('Plugin' + 'Name')
$TemplateLower = ('plugin' + 'name')
$TemplateUpper = ('PLUGIN' + 'NAME')

function ConvertTo-PluginIdentity {
    param([Parameter(Mandatory=$true)][string]$Value)

    $display = $Value.Trim()
    if ([string]::IsNullOrWhiteSpace($display)) {
        throw 'Plugin name cannot be empty.'
    }

    $matches = [regex]::Matches($display, '[A-Za-z0-9]+')
    if ($matches.Count -eq 0) {
        throw 'Plugin name must contain at least one English letter or number.'
    }

    $parts = @()
    foreach ($m in $matches) {
        $part = $m.Value
        if ($part.Length -eq 1) {
            $parts += $part.ToUpperInvariant()
        } else {
            $parts += ($part.Substring(0,1).ToUpperInvariant() + $part.Substring(1))
        }
    }

    $code = ($parts -join '')
    if ($code -notmatch '^[A-Za-z][A-Za-z0-9]*$') {
        throw "Derived code name '$code' is invalid. Start the plugin name with an English letter."
    }

    $slugBase = [regex]::Replace($code, '([a-z0-9])([A-Z])', '$1-$2')
    $slug = ($slugBase -replace '[^A-Za-z0-9]+','-').Trim('-').ToLowerInvariant()
    if ([string]::IsNullOrWhiteSpace($slug)) {
        throw 'Could not derive an npm-safe slug.'
    }

    [pscustomobject]@{
        DisplayName = $display
        CodeName = $code
        Slug = $slug
        Upper = $code.ToUpperInvariant()
    }
}

function Test-SkipTree {
    param([Parameter(Mandatory=$true)][string]$FullName)
    $relative = $FullName.Substring($Root.Length).TrimStart('\','/')
    if ([string]::IsNullOrWhiteSpace($relative)) { return $false }
    $first = ($relative -split '[\\/]')[0]
    return $first -in @('.git','node_modules')
}

function Test-SkipTextContent {
    param(
        [Parameter(Mandatory=$true)][string]$FullName,
        [Parameter(Mandatory=$true)][string]$PersistentDirectoryName
    )
    $relative = $FullName.Substring($Root.Length).TrimStart('\','/')
    if ([string]::IsNullOrWhiteSpace($relative)) { return $false }
    $first = ($relative -split '[\\/]')[0]
    return $first -in @('.git','node_modules','local-secrets','runtime','logs',$PersistentDirectoryName)
}

function Test-TextFile {
    param([Parameter(Mandatory=$true)][System.IO.FileInfo]$File)
    if ($File.Name -in @('.gitignore','LICENSE')) { return $true }
    return $File.Extension.ToLowerInvariant() -in @(
        '.mjs','.js','.cjs','.json','.md','.txt','.yaml','.yml',
        '.ps1','.cmd','.bat','.ts','.tsx','.jsx','.toml','.ini','.conf'
    )
}

function Replace-TemplateTokens {
    param(
        [Parameter(Mandatory=$true)][string]$Text,
        [Parameter(Mandatory=$true)]$Identity
    )
    return $Text.Replace($TemplateToken, $Identity.CodeName).
        Replace($TemplateLower, $Identity.Slug).
        Replace($TemplateUpper, $Identity.Upper)
}

if ([string]::IsNullOrWhiteSpace($Name)) {
    Write-Host ''
    Write-Host '========================================'
    Write-Host ' Base Plugin for ChatGPT - Initialize'
    Write-Host '========================================'
    Write-Host ''
    Write-Host 'Enter the plugin name once. The initializer will rename files/folders'
    Write-Host 'and replace the template identity throughout source, config, docs, and tests.'
    Write-Host ''
    $Name = Read-Host 'Plugin name (example: Fictionlog Writer)'
}

$identity = ConvertTo-PluginIdentity -Value $Name
$persistentOld = $TemplateToken + '-runtime'
$persistentNew = $identity.CodeName + '-runtime'

$templateEntry = Join-Path $Root ($TemplateToken + '.mjs')
if (-not (Test-Path -LiteralPath $templateEntry -PathType Leaf)) {
    throw 'TEMPLATE_ALREADY_INITIALIZED: The template entry file was not found. This repository may already be initialized.'
}

$pathChanges = @()
Get-ChildItem -LiteralPath $Root -Recurse -Force |
    Where-Object {
        -not (Test-SkipTree -FullName $_.FullName) -and
        ($_.Name.Contains($TemplateToken) -or $_.Name.Contains($TemplateLower) -or $_.Name.Contains($TemplateUpper))
    } |
    Sort-Object { $_.FullName.Length } -Descending |
    ForEach-Object {
        $newName = Replace-TemplateTokens -Text $_.Name -Identity $identity
        if ($newName -ne $_.Name) {
            $pathChanges += [pscustomobject]@{
                Old = $_.FullName
                New = Join-Path (Split-Path -Parent $_.FullName) $newName
                IsDirectory = $_.PSIsContainer
            }
        }
    }

$textChanges = @()
Get-ChildItem -LiteralPath $Root -Recurse -File -Force |
    Where-Object {
        -not (Test-SkipTextContent -FullName $_.FullName -PersistentDirectoryName $persistentOld) -and
        (Test-TextFile -File $_)
    } |
    ForEach-Object {
        $text = [System.IO.File]::ReadAllText($_.FullName)
        $next = Replace-TemplateTokens -Text $text -Identity $identity
        if ($next -ne $text) {
            $textChanges += $_.FullName
        }
    }

Write-Host ''
Write-Host 'Identity preview'
Write-Host '----------------'
Write-Host "Display name : $($identity.DisplayName)"
Write-Host "Code name    : $($identity.CodeName)"
Write-Host "npm slug     : $($identity.Slug)"
Write-Host "Path renames : $($pathChanges.Count)"
Write-Host "Text files   : $($textChanges.Count)"
Write-Host ''

if ($Preview) {
    Write-Host 'Preview only; no files were changed.'
    foreach ($item in $pathChanges) {
        Write-Host ('  ' + (Split-Path -Leaf $item.Old) + ' -> ' + (Split-Path -Leaf $item.New))
    }
    exit 0
}

if (-not $Force) {
    $answer = Read-Host 'Apply this plugin identity now? [Y/n]'
    if (-not [string]::IsNullOrWhiteSpace($answer) -and $answer -notmatch '^(?i)y(es)?$') {
        Write-Host 'Initialization cancelled. No files were changed.'
        exit 0
    }
}

foreach ($item in $pathChanges) {
    if (Test-Path -LiteralPath $item.New) {
        throw "Cannot rename '$($item.Old)': target already exists '$($item.New)'."
    }
}

$utf8NoBom = New-Object System.Text.UTF8Encoding($false)

# Rename deepest paths first so nested files are safe before parent directories move.
foreach ($item in $pathChanges) {
    if (-not (Test-Path -LiteralPath $item.Old)) { continue }
    Rename-Item -LiteralPath $item.Old -NewName (Split-Path -Leaf $item.New)
}

# Re-scan after renames and replace template tokens in text content.
Get-ChildItem -LiteralPath $Root -Recurse -File -Force |
    Where-Object {
        -not (Test-SkipTextContent -FullName $_.FullName -PersistentDirectoryName $persistentNew) -and
        (Test-TextFile -File $_)
    } |
    ForEach-Object {
        $text = [System.IO.File]::ReadAllText($_.FullName)
        $next = Replace-TemplateTokens -Text $text -Identity $identity
        if ($next -ne $text) {
            [System.IO.File]::WriteAllText($_.FullName, $next, $utf8NoBom)
        }
    }

$identityFile = Join-Path $Root 'plugin-identity.json'
$identityObject = [ordered]@{
    display_name = $identity.DisplayName
    code_name = $identity.CodeName
    slug = $identity.Slug
    initialized_at = (Get-Date).ToString('o')
}
[System.IO.File]::WriteAllText(
    $identityFile,
    ($identityObject | ConvertTo-Json) + [Environment]::NewLine,
    $utf8NoBom
)

Write-Host ''
Write-Host 'Initialization result: PASS'
Write-Host "Entry point       : $($identity.CodeName).mjs"
Write-Host "Persistent runtime: $persistentNew\"
Write-Host "Identity record   : plugin-identity.json"
Write-Host ''
Write-Host 'Recommended next steps:'
Write-Host '  1. npm install'
Write-Host '  2. npm test'
Write-Host ('  3. Setup-' + $identity.CodeName + '.cmd')
Write-Host ''
Write-Host 'The template placeholder has been replaced across the project.'
