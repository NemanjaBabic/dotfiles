param(
    [Parameter(Mandatory = $true)]
    [string]$BootstrapPath
)

$ErrorActionPreference = 'Stop'

$tempRoot = Join-Path ([IO.Path]::GetTempPath()) ("herdr bootstrap tests " + [guid]::NewGuid())
$repoRoot = Join-Path $tempRoot 'dotfiles clone with spaces'
$windowsDir = Join-Path $repoRoot 'windows'
$configPath = Join-Path $repoRoot 'windows/config/herdr/config.toml'
$weztermConfigPath = Join-Path $repoRoot 'shared/config/wezterm/wezterm.lua'
$nvimConfigPath = Join-Path $repoRoot 'shared/config/nvim/init.lua'
$psProfileConfigPath = Join-Path $repoRoot 'windows/config/powershell/profile.ps1'
$previousConfigPath = $env:HERDR_CONFIG_PATH

try {
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $configPath) | Out-Null
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $weztermConfigPath) | Out-Null
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $nvimConfigPath) | Out-Null
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $psProfileConfigPath) | Out-Null
    New-Item -ItemType Directory -Force -Path $windowsDir | Out-Null
    Copy-Item -LiteralPath $BootstrapPath -Destination $windowsDir
    Set-Content -LiteralPath $configPath -Value '[keys]' -NoNewline
    Set-Content -LiteralPath $weztermConfigPath -Value '-- wezterm' -NoNewline
    Set-Content -LiteralPath $nvimConfigPath -Value '-- nvim' -NoNewline
    Set-Content -LiteralPath $psProfileConfigPath -Value '# profile' -NoNewline
    . (Join-Path $windowsDir 'bootstrap-windows.ps1')

    $script:userWrites = @()
    $env:HERDR_CONFIG_PATH = 'unchanged-before-bootstrap'
    $setUserVariable = {
        param($Name, $Value, $Target)
        $script:userWrites += [pscustomobject]@{
            Name = $Name
            Value = $Value
            Target = $Target
        }
    }

    Push-Location ([IO.Path]::GetTempPath())
    try {
        Set-HerdrConfigPath -ScriptRoot $windowsDir -WindowsPlatform $true `
            -SetUserEnvironmentVariable $setUserVariable | Out-Null
        $expectedPath = [IO.Path]::GetFullPath($configPath)
        if ($env:HERDR_CONFIG_PATH -cne $expectedPath) {
            throw 'The current-process variable did not resolve from the script root.'
        }

        Set-HerdrConfigPath -ScriptRoot $windowsDir -WindowsPlatform $true `
            -SetUserEnvironmentVariable $setUserVariable | Out-Null
    }
    finally {
        Pop-Location
    }

    if ($script:userWrites.Count -ne 2) {
        throw 'Repeated bootstrap calls should set the user variable idempotently.'
    }
    foreach ($write in $script:userWrites) {
        if ($write.Name -cne 'HERDR_CONFIG_PATH' -or
            $write.Value -cne $expectedPath -or
            $write.Target -cne 'User') {
            throw 'The user environment variable was not assigned the expected name, path, and scope.'
        }
    }

    $script:userWrites = @()
    $env:HERDR_CONFIG_PATH = 'unchanged-before-missing-config'
    $missingRoot = Join-Path $tempRoot 'missing clone'
    $missingWindows = Join-Path $missingRoot 'windows'
    try {
        Set-HerdrConfigPath -ScriptRoot $missingWindows -WindowsPlatform $true `
            -SetUserEnvironmentVariable $setUserVariable | Out-Null
        throw 'A missing config file should fail.'
    }
    catch {
        if ($_.Exception.Message -notlike 'Herdr config file not found:*') {
            throw
        }
    }
    if ($env:HERDR_CONFIG_PATH -cne 'unchanged-before-missing-config' -or
        $script:userWrites.Count -ne 0) {
        throw 'A missing config file must not change either environment scope.'
    }

    # Test WezTerm bootstrap
    $mockHome = Join-Path $tempRoot 'mock_home'
    New-Item -ItemType Directory -Force -Path $mockHome | Out-Null
    $mockWezterm = Join-Path $mockHome '.wezterm.lua'
    Set-Content -LiteralPath $mockWezterm -Value 'old wezterm content'
    $res = Set-WezTermBootstrap -RepoRoot $repoRoot -HomeDirectory $mockHome
    if (-not (Test-Path -LiteralPath "$mockWezterm.bak")) {
        throw 'WezTerm backup was not created for differing file.'
    }
    $weztermContent = Get-Content -LiteralPath $mockWezterm -Raw
    $expectedWeztermSlash = ([IO.Path]::GetFullPath($weztermConfigPath)).Replace('\', '/')
    if (-not $weztermContent.Contains("return dofile(`"$expectedWeztermSlash`")")) {
        throw 'WezTerm file does not contain expected return dofile line with forward slashes.'
    }
    # Idempotent re-run should not rewrite or re-backup
    $res2 = Set-WezTermBootstrap -RepoRoot $repoRoot -HomeDirectory $mockHome
    if ($res2.Action -cne 'Unchanged') {
        throw 'WezTerm bootstrap is not idempotent when content matches.'
    }

    # Test Neovim bootstrap
    $mockLocalAppData = Join-Path $tempRoot 'mock_localappdata'
    $mockNvimInit = Join-Path $mockLocalAppData 'nvim/init.lua'
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $mockNvimInit) | Out-Null
    Set-Content -LiteralPath $mockNvimInit -Value 'old nvim content'
    $nvimRes = Set-NeovimBootstrap -RepoRoot $repoRoot -LocalAppData $mockLocalAppData
    if (-not (Test-Path -LiteralPath "$mockNvimInit.bak")) {
        throw 'Neovim backup was not created for differing file.'
    }
    $nvimContent = Get-Content -LiteralPath $mockNvimInit -Raw
    $expectedNvimSlash = ([IO.Path]::GetFullPath($nvimConfigPath)).Replace('\', '/')
    if (-not $nvimContent.Contains("dofile(`"$expectedNvimSlash`")")) {
        throw 'Neovim init.lua does not contain expected dofile line with forward slashes.'
    }
    # Idempotent re-run
    $nvimRes2 = Set-NeovimBootstrap -RepoRoot $repoRoot -LocalAppData $mockLocalAppData
    if ($nvimRes2.Action -cne 'Unchanged') {
        throw 'Neovim bootstrap is not idempotent when content matches.'
    }

    # Test PowerShell profile bootstrap
    $mockProfileDir = Join-Path $tempRoot 'mock_profile_dir'
    $mockProfilePath = Join-Path $mockProfileDir 'Microsoft.PowerShell_profile.ps1'
    # Profile directory doesn't exist yet
    $psRes = Set-PowerShellProfileBootstrap -RepoRoot $repoRoot -ProfilePath $mockProfilePath
    if ($psRes.Action -cne 'Created') {
        throw 'PowerShell profile was not created when missing.'
    }
    $psContent = Get-Content -LiteralPath $mockProfilePath -Raw
    $expectedPsPath = [IO.Path]::GetFullPath($psProfileConfigPath)
    if (-not $psContent.Contains(". `"$expectedPsPath`"")) {
        throw 'PowerShell profile does not contain dot-source line.'
    }
    # Re-run should be unchanged
    $psRes2 = Set-PowerShellProfileBootstrap -RepoRoot $repoRoot -ProfilePath $mockProfilePath
    if ($psRes2.Action -cne 'Unchanged') {
        throw 'PowerShell profile bootstrap is not idempotent.'
    }
    # Direct starship warning test
    Set-Content -LiteralPath $mockProfilePath -Value "Invoke-Expression (& starship init powershell)`n"
    $warnOutput = Set-PowerShellProfileBootstrap -RepoRoot $repoRoot -ProfilePath $mockProfilePath
    if ($warnOutput.Action -cne 'Skipped') {
        throw 'Direct starship init was not detected.'
    }

    if ([Environment]::OSVersion.Platform -ne [PlatformID]::Win32NT) {
        try {
            & (Join-Path $windowsDir 'bootstrap-windows.ps1') 2>$null
            throw 'A non-Windows invocation should fail.'
        }
        catch {
            if ($_.Exception.Message -notlike '*can only be run on Windows*') {
                throw
            }
        }
    }

    Write-Output 'ok - Windows bootstrap resolves spaced paths, sets user and process values idempotently, and bootstraps WezTerm, Neovim, Profile, and Herdr'
}
finally {
    if ($null -eq $previousConfigPath) {
        Remove-Item Env:HERDR_CONFIG_PATH -ErrorAction SilentlyContinue
    }
    else {
        $env:HERDR_CONFIG_PATH = $previousConfigPath
    }
    Remove-Item -LiteralPath $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
}
