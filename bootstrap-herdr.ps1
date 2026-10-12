function Set-HerdrConfigPath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ScriptRoot,
        [scriptblock]$SetUserEnvironmentVariable = {
            param($Name, $Value, $Target)
            [Environment]::SetEnvironmentVariable($Name, $Value, $Target)
        },
        [bool]$WindowsPlatform = ([Environment]::OSVersion.Platform -eq [PlatformID]::Win32NT)
    )

    if (-not $WindowsPlatform) {
        throw 'bootstrap-herdr.ps1 can only be run on Windows.'
    }

    $configPath = [IO.Path]::GetFullPath(
        (Join-Path $ScriptRoot 'home/.config/herdr/config.toml')
    )

    if (-not (Test-Path -LiteralPath $configPath -PathType Leaf)) {
        throw "Herdr config file not found: $configPath. No environment variables were changed."
    }

    & $SetUserEnvironmentVariable 'HERDR_CONFIG_PATH' $configPath 'User'
    $env:HERDR_CONFIG_PATH = $configPath

    Write-Output "HERDR_CONFIG_PATH set to $configPath for this user and PowerShell session."
}

if ($MyInvocation.InvocationName -ne '.') {
    Set-HerdrConfigPath -ScriptRoot $PSScriptRoot
}
