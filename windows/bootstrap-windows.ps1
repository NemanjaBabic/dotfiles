<#
.SYNOPSIS
    Bootstraps dotfiles configuration on a fresh Windows machine.

.DESCRIPTION
    Configures WezTerm, Neovim, PowerShell, Copilot CLI, and Herdr after installing the prerequisite tools:
    1. Sets up $HOME\.wezterm.lua to load the shared WezTerm configuration via dofile.
    2. Sets up $env:LOCALAPPDATA\nvim\init.lua to load the shared Neovim configuration via dofile.
    3. Configures $PROFILE to dot-source windows\config\powershell\profile.ps1.
    4. Symlinks Copilot CLI settings and global instructions to the shared configuration.
    5. Sets HERDR_CONFIG_PATH in both the current process and the Windows User environment scope.
    6. Validates prerequisites (PowerShell 7, WezTerm, Herdr, Starship, Neovim, Git, ripgrep, fd, Hack Nerd Font).

    Idempotent and safe to re-run. Backs up existing files before replacing differing content.
#>

function Set-HerdrConfigPath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$ScriptRoot,
        [Parameter(Mandatory = $false)]
        [string]$RepoRoot,
        [scriptblock]$SetUserEnvironmentVariable = {
            param($Name, $Value, $Target)
            [Environment]::SetEnvironmentVariable($Name, $Value, $Target)
        },
        [bool]$WindowsPlatform = ([Environment]::OSVersion.Platform -eq [PlatformID]::Win32NT)
    )

    if (-not $WindowsPlatform) {
        throw 'bootstrap-windows.ps1 can only be run on Windows.'
    }

    $root = if ($RepoRoot) {
        $RepoRoot
    } elseif ($ScriptRoot) {
        if (Test-Path -LiteralPath (Join-Path $ScriptRoot 'windows/config/herdr/config.toml') -PathType Leaf) {
            $ScriptRoot
        } elseif (Test-Path -LiteralPath (Join-Path $ScriptRoot 'config/herdr/config.toml') -PathType Leaf) {
            Join-Path $ScriptRoot '..'
        } else {
            $ScriptRoot
        }
    } else {
        Join-Path $PSScriptRoot '..'
    }

    $configPath = [IO.Path]::GetFullPath(
        (Join-Path $root 'windows/config/herdr/config.toml')
    )

    if (-not (Test-Path -LiteralPath $configPath -PathType Leaf)) {
        throw "Herdr config file not found: $configPath. No environment variables were changed."
    }

    & $SetUserEnvironmentVariable 'HERDR_CONFIG_PATH' $configPath 'User'
    $env:HERDR_CONFIG_PATH = $configPath

    Write-Host "HERDR_CONFIG_PATH set to $configPath for this user and PowerShell session."
    return $configPath
}

function Set-WezTermBootstrap {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$RepoRoot,
        [string]$HomeDirectory = $HOME
    )

    $resolvedRepo = [IO.Path]::GetFullPath($RepoRoot)
    $luaRepoRoot = $resolvedRepo -replace '\\', '/'
    $weztermTarget = "$luaRepoRoot/shared/config/wezterm/wezterm.lua"
    $expectedContent = "return dofile(`"$weztermTarget`")"

    $weztermFile = Join-Path $HomeDirectory '.wezterm.lua'

    if (Test-Path -LiteralPath $weztermFile -PathType Leaf) {
        $existing = Get-Content -LiteralPath $weztermFile -Raw
        if ($null -ne $existing -and $existing.Trim() -eq $expectedContent.Trim()) {
            return [pscustomobject]@{
                Action = 'Unchanged'
                Path = $weztermFile
                Message = "WezTerm bootstrap already up to date: $weztermFile"
            }
        }

        $bak = "$weztermFile.bak"
        Copy-Item -LiteralPath $weztermFile -Destination $bak -Force
        Set-Content -LiteralPath $weztermFile -Value $expectedContent
        return [pscustomobject]@{
            Action = 'Updated'
            Path = $weztermFile
            Backup = $bak
            Message = "WezTerm bootstrap backed up to $bak and updated: $weztermFile"
        }
    }

    Set-Content -LiteralPath $weztermFile -Value $expectedContent
    return [pscustomobject]@{
        Action = 'Created'
        Path = $weztermFile
        Message = "WezTerm bootstrap created: $weztermFile"
    }
}

function Set-NeovimBootstrap {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$RepoRoot,
        [string]$LocalAppData = $env:LOCALAPPDATA
    )

    $resolvedRepo = [IO.Path]::GetFullPath($RepoRoot)
    $luaRepoRoot = $resolvedRepo -replace '\\', '/'
    $nvimTarget = "$luaRepoRoot/shared/config/nvim/init.lua"
    $expectedContent = "dofile(`"$nvimTarget`")"

    $nvimDir = Join-Path $LocalAppData 'nvim'
    if (-not (Test-Path -LiteralPath $nvimDir -PathType Container)) {
        New-Item -ItemType Directory -Force -Path $nvimDir | Out-Null
    }

    $nvimFile = Join-Path $nvimDir 'init.lua'

    if (Test-Path -LiteralPath $nvimFile -PathType Leaf) {
        $existing = Get-Content -LiteralPath $nvimFile -Raw
        if ($null -ne $existing -and $existing.Trim() -eq $expectedContent.Trim()) {
            return [pscustomobject]@{
                Action = 'Unchanged'
                Path = $nvimFile
                Message = "Neovim init.lua already up to date: $nvimFile"
            }
        }

        $bak = "$nvimFile.bak"
        Copy-Item -LiteralPath $nvimFile -Destination $bak -Force
        Set-Content -LiteralPath $nvimFile -Value $expectedContent
        return [pscustomobject]@{
            Action = 'Updated'
            Path = $nvimFile
            Backup = $bak
            Message = "Neovim init.lua backed up to $bak and updated: $nvimFile"
        }
    }

    Set-Content -LiteralPath $nvimFile -Value $expectedContent
    return [pscustomobject]@{
        Action = 'Created'
        Path = $nvimFile
        Message = "Neovim init.lua created: $nvimFile"
    }
}

function Set-PowerShellProfileBootstrap {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$RepoRoot,
        [string]$ProfilePath = $PROFILE
    )

    $resolvedRepo = [IO.Path]::GetFullPath($RepoRoot)
    $profileScript = [IO.Path]::GetFullPath(
        (Join-Path $resolvedRepo 'windows/config/powershell/profile.ps1')
    )
    $dotSourceLine = ". `"$profileScript`""

    $profileDir = Split-Path -Parent $ProfilePath
    if (-not (Test-Path -LiteralPath $profileDir -PathType Container)) {
        New-Item -ItemType Directory -Force -Path $profileDir | Out-Null
    }

    if (Test-Path -LiteralPath $ProfilePath -PathType Leaf) {
        $existing = Get-Content -LiteralPath $ProfilePath -Raw
        if ($null -eq $existing) { $existing = '' }

        if ($existing -match '(?m)^\s*\.\s+["'']?.*[/\\]windows[/\\]config[/\\]powershell[/\\]profile\.ps1["'']?\s*$') {
            return [pscustomobject]@{
                Action = 'Unchanged'
                Path = $ProfilePath
                Message = "PowerShell profile already dot-sources profile.ps1: $ProfilePath"
            }
        }

        if ($existing -match '(?m)starship\s+init\s+powershell') {
            Write-Warning "Found existing direct Starship initialization in $ProfilePath (``Invoke-Expression (& starship init powershell)``)."
            Write-Warning "Skipped modifying `$PROFILE to avoid duplicate prompt initialization."
            Write-Warning "Please manually remove the direct Starship initialization from $ProfilePath and replace it with:"
            Write-Warning "  $dotSourceLine"
            return [pscustomobject]@{
                Action = 'Skipped'
                Path = $ProfilePath
                Warning = 'Direct Starship initialization found; manual update required'
                Message = "PowerShell profile skipped due to direct starship init conflict: $ProfilePath"
            }
        }

        $bak = "$ProfilePath.bak"
        Copy-Item -LiteralPath $ProfilePath -Destination $bak -Force

        $appendContent = if ($existing.Length -gt 0 -and -not ($existing.EndsWith("`n") -or $existing.EndsWith("`r`n"))) {
            "`r`n$dotSourceLine`r`n"
        } else {
            "$dotSourceLine`r`n"
        }
        [IO.File]::AppendAllText($ProfilePath, $appendContent)

        return [pscustomobject]@{
            Action = 'Updated'
            Path = $ProfilePath
            Backup = $bak
            Message = "PowerShell profile backed up to $bak and appended dot-source line: $ProfilePath"
        }
    }

    Set-Content -LiteralPath $ProfilePath -Value $dotSourceLine
    return [pscustomobject]@{
        Action = 'Created'
        Path = $ProfilePath
        Message = "PowerShell profile created with dot-source line: $ProfilePath"
    }
}

function Set-CopilotBootstrap {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$RepoRoot,
        [string]$HomeDirectory = $HOME,
        [scriptblock]$NewSymbolicLink = {
            param($Path, $Target)
            New-Item -ItemType SymbolicLink -Path $Path -Target $Target -ErrorAction Stop
        }
    )

    $resolvedRepo = [IO.Path]::GetFullPath($RepoRoot)
    $copilotDir = Join-Path $HomeDirectory '.copilot'
    if (-not (Test-Path -LiteralPath $copilotDir -PathType Container)) {
        New-Item -ItemType Directory -Force -Path $copilotDir | Out-Null
    }

    $links = @(
        @{
            Path = Join-Path $copilotDir 'settings.json'
            Target = [IO.Path]::GetFullPath((Join-Path $resolvedRepo 'shared/.copilot/settings.json'))
        }
        @{
            Path = Join-Path $copilotDir 'copilot-instructions.md'
            Target = [IO.Path]::GetFullPath((Join-Path $resolvedRepo 'shared/AGENTS.md'))
        }
    )
    $linkResults = @()

    foreach ($link in $links) {
        $path = $link.Path
        $target = $link.Target
        $item = Get-Item -LiteralPath $path -Force -ErrorAction SilentlyContinue

        if ($null -ne $item -and $item.LinkType -eq 'SymbolicLink' -and $item.Target) {
            $existingTarget = [string]@($item.Target)[0]
            if (-not [IO.Path]::IsPathRooted($existingTarget)) {
                $existingTarget = Join-Path (Split-Path -Parent $path) $existingTarget
            }
            $existingTarget = [IO.Path]::GetFullPath($existingTarget)
            $pathComparison = if ([IO.Path]::DirectorySeparatorChar -eq '\') {
                [StringComparison]::OrdinalIgnoreCase
            } else {
                [StringComparison]::Ordinal
            }

            if ([string]::Equals($existingTarget, $target, $pathComparison)) {
                $linkResults += [pscustomobject]@{
                    Action = 'Unchanged'
                    Path = $path
                    Target = $target
                    Message = "Copilot symlink already up to date: $path"
                }
                continue
            }
        }

        $backup = $null
        if ($null -ne $item) {
            $backup = "$path.bak"
            Move-Item -LiteralPath $path -Destination $backup -Force -ErrorAction Stop
        }

        try {
            & $NewSymbolicLink $path $target | Out-Null
            $action = if ($backup) { 'Updated' } else { 'Created' }
            $message = if ($backup) {
                "Copilot path backed up to $backup and linked: $path"
            } else {
                "Copilot symlink created: $path"
            }
            $linkResults += [pscustomobject]@{
                Action = $action
                Path = $path
                Target = $target
                Backup = $backup
                Message = $message
            }
        }
        catch {
            $warning = "Could not create Copilot symlink at $path. Windows requires Developer Mode or an elevated PowerShell session to create symbolic links. Enable Developer Mode or run PowerShell as Administrator, then rerun the bootstrap. Error: $($_.Exception.Message)"
            Write-Warning $warning
            $linkResults += [pscustomobject]@{
                Action = 'Failed'
                Path = $path
                Target = $target
                Backup = $backup
                Warning = $warning
                Message = $warning
            }
        }
    }

    $action = if (@($linkResults | Where-Object Action -eq 'Failed').Count -gt 0) {
        'Failed'
    } elseif (@($linkResults | Where-Object Action -eq 'Updated').Count -gt 0) {
        'Updated'
    } elseif (@($linkResults | Where-Object Action -eq 'Created').Count -gt 0) {
        'Created'
    } else {
        'Unchanged'
    }

    return [pscustomobject]@{
        Action = $action
        Path = $copilotDir
        Links = $linkResults
        Message = "Copilot CLI links: $action ($copilotDir)"
    }
}

function Test-Prerequisites {
    [CmdletBinding()]
    param(
        [scriptblock]$GetCommand = {
            param($Name)
            Get-Command -Name $Name -ErrorAction SilentlyContinue
        }
    )

    $tools = @(
        @{ Name = 'pwsh'; Description = 'PowerShell 7' }
        @{ Name = 'wezterm'; Description = 'WezTerm' }
        @{ Name = 'herdr'; Description = 'Herdr' }
        @{ Name = 'starship'; Description = 'Starship' }
        @{ Name = 'nvim'; Description = 'Neovim' }
        @{ Name = 'git'; Description = 'Git' }
        @{ Name = 'rg'; Description = 'ripgrep' }
        @{ Name = 'fd'; Description = 'fd' }
    )

    $missing = @()
    $installed = @()

    foreach ($tool in $tools) {
        $cmd = & $GetCommand $tool.Name
        if ($cmd) {
            $installed += $tool
        } else {
            $missing += $tool
        }
    }

    return [pscustomobject]@{
        Installed = $installed
        Missing = $missing
    }
}

function Initialize-WindowsDotfiles {
    [CmdletBinding()]
    param(
        [string]$ScriptRoot = $PSScriptRoot,
        [string]$RepoRoot,
        [string]$HomeDirectory = $HOME,
        [string]$LocalAppData = $env:LOCALAPPDATA,
        [string]$ProfilePath = $PROFILE,
        [scriptblock]$SetUserEnvironmentVariable = {
            param($Name, $Value, $Target)
            [Environment]::SetEnvironmentVariable($Name, $Value, $Target)
        },
        [scriptblock]$GetCommand = {
            param($Name)
            Get-Command -Name $Name -ErrorAction SilentlyContinue
        },
        [scriptblock]$NewSymbolicLink = {
            param($Path, $Target)
            New-Item -ItemType SymbolicLink -Path $Path -Target $Target -ErrorAction Stop
        },
        [bool]$WindowsPlatform = ([Environment]::OSVersion.Platform -eq [PlatformID]::Win32NT)
    )

    if (-not $WindowsPlatform) {
        throw 'bootstrap-windows.ps1 can only be run on Windows.'
    }

    $resolvedRepo = if ($RepoRoot) {
        [IO.Path]::GetFullPath($RepoRoot)
    } elseif ($ScriptRoot) {
        if (Test-Path -LiteralPath (Join-Path $ScriptRoot 'windows/config/herdr/config.toml') -PathType Leaf) {
            [IO.Path]::GetFullPath($ScriptRoot)
        } else {
            [IO.Path]::GetFullPath((Join-Path $ScriptRoot '..'))
        }
    } else {
        [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
    }

    Write-Output "==> Bootstrapping Windows dotfiles from: $resolvedRepo"

    # 1. WezTerm
    $weztermResult = Set-WezTermBootstrap -RepoRoot $resolvedRepo -HomeDirectory $HomeDirectory
    Write-Output "    $($weztermResult.Message)"

    # 2. Neovim
    $nvimResult = Set-NeovimBootstrap -RepoRoot $resolvedRepo -LocalAppData $LocalAppData
    Write-Output "    $($nvimResult.Message)"

    # 3. PowerShell Profile
    $profileResult = Set-PowerShellProfileBootstrap -RepoRoot $resolvedRepo -ProfilePath $ProfilePath
    Write-Output "    $($profileResult.Message)"

    # 4. Copilot CLI
    $copilotResult = Set-CopilotBootstrap -RepoRoot $resolvedRepo -HomeDirectory $HomeDirectory `
        -NewSymbolicLink $NewSymbolicLink
    Write-Output "    $($copilotResult.Message)"

    # 5. Herdr Config Path
    $herdrPath = Set-HerdrConfigPath -RepoRoot $resolvedRepo `
        -SetUserEnvironmentVariable $SetUserEnvironmentVariable `
        -WindowsPlatform $WindowsPlatform

    # 6. Prerequisites check
    $prereqs = Test-Prerequisites -GetCommand $GetCommand

    Write-Output ""
    Write-Output "==> Summary of Changes:"
    Write-Output "    - WezTerm: $($weztermResult.Action) ($($weztermResult.Path))"
    Write-Output "    - Neovim: $($nvimResult.Action) ($($nvimResult.Path))"
    Write-Output "    - PowerShell `$PROFILE: $($profileResult.Action) ($($profileResult.Path))"
    Write-Output "    - Copilot CLI: $($copilotResult.Action) ($($copilotResult.Path))"
    Write-Output "    - HERDR_CONFIG_PATH: Set to $herdrPath (Process and User scope)"

    Write-Output ""
    Write-Output "==> Prerequisite Status:"
    if ($prereqs.Missing.Count -eq 0) {
        Write-Output "    All CLI tools found on PATH (pwsh, wezterm, herdr, starship, nvim, git, rg, fd)."
    } else {
        Write-Output "    The following prerequisites were NOT found on PATH:"
        foreach ($m in $prereqs.Missing) {
            Write-Output "      - $($m.Description) ($($m.Name))"
        }
        Write-Output "    Please install them manually and ensure they are available on PATH."
    }
    Write-Output "    Ensure 'Hack Nerd Font' is installed from https://www.nerdfonts.com/font-downloads for icons."

    return [pscustomobject]@{
        RepoRoot = $resolvedRepo
        WezTerm = $weztermResult
        Neovim = $nvimResult
        Profile = $profileResult
        Copilot = $copilotResult
        HerdrConfigPath = $herdrPath
        Prerequisites = $prereqs
    }
}

if ($MyInvocation.InvocationName -ne '.') {
    Initialize-WindowsDotfiles
}
