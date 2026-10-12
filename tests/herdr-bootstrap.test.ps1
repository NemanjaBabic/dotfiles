param(
    [Parameter(Mandatory = $true)]
    [string]$BootstrapPath
)

$ErrorActionPreference = 'Stop'

$tempRoot = Join-Path ([IO.Path]::GetTempPath()) ("herdr bootstrap tests " + [guid]::NewGuid())
$repoRoot = Join-Path $tempRoot 'dotfiles clone with spaces'
$configPath = Join-Path $repoRoot 'home/.config/herdr/config.toml'
$previousConfigPath = $env:HERDR_CONFIG_PATH

try {
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $configPath) | Out-Null
    Copy-Item -LiteralPath $BootstrapPath -Destination $repoRoot
    Set-Content -LiteralPath $configPath -Value '[keys]' -NoNewline
    . (Join-Path $repoRoot 'bootstrap-herdr.ps1')

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
        Set-HerdrConfigPath -ScriptRoot $repoRoot -WindowsPlatform $true `
            -SetUserEnvironmentVariable $setUserVariable | Out-Null
        $expectedPath = [IO.Path]::GetFullPath($configPath)
        if ($env:HERDR_CONFIG_PATH -cne $expectedPath) {
            throw 'The current-process variable did not resolve from the script root.'
        }

        Set-HerdrConfigPath -ScriptRoot $repoRoot -WindowsPlatform $true `
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
    try {
        Set-HerdrConfigPath -ScriptRoot $missingRoot -WindowsPlatform $true `
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

    if ([Environment]::OSVersion.Platform -ne [PlatformID]::Win32NT) {
        try {
            & (Join-Path $repoRoot 'bootstrap-herdr.ps1') 2>$null
            throw 'A non-Windows invocation should fail.'
        }
        catch {
            if ($_.Exception.Message -notlike '*can only be run on Windows*') {
                throw
            }
        }
    }

    Write-Output 'ok - Herdr bootstrap resolves spaced paths, sets user and process values idempotently, and leaves both unchanged when config is missing'
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
