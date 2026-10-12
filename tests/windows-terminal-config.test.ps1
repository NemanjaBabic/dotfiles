param(
    [Parameter(Mandatory = $true)]
    [string]$RepositoryRoot
)

$ErrorActionPreference = 'Stop'

$tempRoot = Join-Path ([IO.Path]::GetTempPath()) ("dotfiles profile test " + [guid]::NewGuid())
$cloneRoot = Join-Path $tempRoot 'clone with spaces'
$profileDirectory = Join-Path $cloneRoot 'windows/config/powershell'
$starshipPath = Join-Path $cloneRoot 'shared/config/starship/starship.toml'
$previousStarshipConfig = $env:STARSHIP_CONFIG

try {
    New-Item -ItemType Directory -Force -Path $profileDirectory | Out-Null
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $starshipPath) | Out-Null
    Set-Content -LiteralPath $starshipPath -Value '[character]' -NoNewline
    Copy-Item -LiteralPath (Join-Path $RepositoryRoot 'windows/config/powershell/profile.ps1') `
        -Destination $profileDirectory

    function starship {
        param($Command, $Shell)
        'function global:prompt { ''profile-test> '' }'
    }
    . (Join-Path $profileDirectory 'profile.ps1')

    $expectedStarshipPath = [IO.Path]::GetFullPath($starshipPath)
    if ($env:STARSHIP_CONFIG -cne $expectedStarshipPath -or $env:STARSHIP_CONFIG.Contains('..')) {
        throw 'The shared profile did not publish the normalized Starship config path.'
    }

    $herdrConfig = Get-Content -LiteralPath (Join-Path $RepositoryRoot 'windows/config/herdr/config.toml') -Raw
    if ($herdrConfig -notmatch '(?m)^\[terminal\]\s*$' -or
        $herdrConfig -notmatch '(?m)^default_shell\s*=\s*"pwsh\.exe"\s*$' -or
        $herdrConfig -match '(?m)^\[shell\]\s*$') {
        throw 'Herdr must use the supported Windows [terminal] default_shell setting, not [shell].'
    }

    $weztermConfig = Get-Content -LiteralPath (Join-Path $RepositoryRoot 'shared/config/wezterm/wezterm.lua') -Raw
    if ($weztermConfig -notmatch 'config\.default_prog\s*=\s*\{\s*"pwsh\.exe",\s*"-NoLogo"\s*\}') {
        throw 'WezTerm and Herdr must both explicitly default to PowerShell 7 on Windows.'
    }

    $readme = Get-Content -LiteralPath (Join-Path $RepositoryRoot 'windows/README.md') -Raw
    foreach ($requiredText in @(
        '[Environment]::SetEnvironmentVariable(''HERDR_CONFIG_PATH''',
        '[Environment]::GetEnvironmentVariable(''HERDR_CONFIG_PATH'', ''User'')',
        '$PSVersionTable.PSVersion',
        '(Get-Process -Id $PID).Path',
        'Get-Content -LiteralPath $PROFILE',
        'Get-Command starship',
        'herdr server reload-config',
        'macOS uses `unix/config/herdr/config.toml`',
        'fresh Windows machine using default settings',
        'bootstrap script configures them but does not install them',
        'git clone https://github.com/NemanjaBabic/dotfiles.git',
        'New-Item -ItemType Directory -Force -Path ''C:\Git''',
        'Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned'
    )) {
        if (-not $readme.Contains($requiredText)) {
            throw "The Windows README is missing required setup or verification text: $requiredText"
        }
    }

    foreach ($readmePath in @('README.md', 'windows/README.md', 'unix/README.md', 'shared/README.md')) {
        $documentation = Get-Content -LiteralPath (Join-Path $RepositoryRoot $readmePath) -Raw
        if ($documentation -match 'previous layout|old layout|home/|migrat') {
            throw "The setup documentation still references the obsolete layout: $readmePath"
        }
    }

    Write-Output 'ok - Starship path normalization handles spaced clones and Windows terminal defaults and documentation stay aligned'
}
finally {
    if ($null -eq $previousStarshipConfig) {
        Remove-Item Env:STARSHIP_CONFIG -ErrorAction SilentlyContinue
    }
    else {
        $env:STARSHIP_CONFIG = $previousStarshipConfig
    }
    Remove-Item -LiteralPath $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
}
