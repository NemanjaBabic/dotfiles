# Windows Setup (WezTerm, Starship, Neovim, and Herdr)

Windows uses the shared application configs (`shared/`) and Windows-specific configs (`windows/`) directly, not the macOS Nix setup.
Do not run `unix/bootstrap.sh` or `unix/rebuild.sh` on Windows.

## Migrating an existing machine (Upgrading from the old layout)

> [!WARNING]
> **Breaking changes for existing machines:**
> This repository restructured its layout to separate macOS/Unix files (`unix/`), Windows files (`windows/`), and shared application configs (`shared/`).
> Previously, configurations lived under `home/` (e.g. `home/.config/wezterm`, `home/.config/nvim`, `home/.config/herdr`, `home/.config/powershell`).
> 
> If you previously configured your Windows machine:
> - `$HOME\.wezterm.lua` points to the old `home/.config/wezterm/wezterm.lua` path and will fail to load.
> - `$env:LOCALAPPDATA\nvim\init.lua` points to the old `home/.config/nvim/init.lua` path and will fail to load.
> - `$PROFILE` dot-sources the old `home/.config/powershell/profile.ps1` path.
> - `HERDR_CONFIG_PATH` (in the process and Windows User environment) points to the old `home/.config/herdr/config.toml` path.
> 
> **To fix all linkages automatically:**
> Simply pull the latest changes and run `windows/bootstrap-windows.ps1`:
> 
> ```powershell
> git pull
> & .\windows\bootstrap-windows.ps1
> ```
> 
> The script is idempotent and automatically updates `$HOME\.wezterm.lua`, `$env:LOCALAPPDATA\nvim\init.lua`, `$PROFILE`, and `HERDR_CONFIG_PATH` to point to their new locations under `shared/` and `windows/`, backing up any differing files first.

## Automated Setup (Recommended)

Run `windows/bootstrap-windows.ps1` from a PowerShell 7 session:

```powershell
& ".\windows\bootstrap-windows.ps1"
```

The script automatically:
1. Creates or updates `$HOME\.wezterm.lua` with `return dofile("<repo-root>/shared/config/wezterm/wezterm.lua")` (with forward slashes for Lua), backing up any pre-existing differing file to `.wezterm.lua.bak`.
2. Creates or updates `$env:LOCALAPPDATA\nvim\init.lua` with `dofile("<repo-root>/shared/config/nvim/init.lua")`, backing up any pre-existing differing file to `init.lua.bak`.
3. Ensures `$PROFILE`'s directory exists, backs up an existing profile to `$PROFILE.bak`, and appends a line dot-sourcing `<repo-root>\windows\config\powershell\profile.ps1`.
4. Validates that `<repo-root>\windows\config\herdr\config.toml` exists, and sets `HERDR_CONFIG_PATH` for both the current process and the Windows User environment scope.
5. Verifies prerequisite tools on `PATH` and reports missing dependencies.

---

## Prerequisites

Install PowerShell 7, WezTerm, Herdr, Starship, a current stable Neovim (0.10 or newer), Git, ripgrep, and fd.
Add `pwsh.exe`, `starship`, `nvim`, `git`, `rg`, and `fd` to `PATH`; Git is needed for plugin installation, ripgrep for text search, and fd for file picking. Herdr's explicit default requires `pwsh.exe` on `PATH`.
Install **Hack Nerd Font** from [Nerd Fonts](https://www.nerdfonts.com/font-downloads) so WezTerm can use the configured font and display prompt and plugin icons.
Install Herdr using the [official installation instructions](https://herdr.dev/docs/install/).

Confirm the executables are discoverable in PowerShell before configuring the terminals:

```powershell
Get-Command pwsh, starship, nvim, git, rg, fd
```

---

## Manual Walkthrough (Fallback)

If you prefer to configure your environment manually instead of running `windows/bootstrap-windows.ps1`, follow these steps:

### 1. WezTerm

Create or update `$HOME\.wezterm.lua` to point to the shared WezTerm configuration (replace `<repo-root>` with the absolute path using forward slashes):

```lua
return dofile("<repo-root>/shared/config/wezterm/wezterm.lua")
```

The tracked WezTerm config sets its Windows default command to `pwsh.exe -NoLogo`;
because it does not use `-NoProfile`, PowerShell loads its normal startup profile. The default shell on other platforms is unchanged.

### 2. Neovim

Back up any existing Neovim configuration before changing its entry point. For the default Windows location, create `$env:LOCALAPPDATA\nvim` if needed and put this in `$env:LOCALAPPDATA\nvim\init.lua` (replace `<repo-root>` with the absolute path using forward slashes):

```lua
dofile("<repo-root>/shared/config/nvim/init.lua")
```

The repository's entry point adds its own directory to Neovim's runtime path before loading modules.
Its three `require` calls intentionally load settings, plugins, and keybindings from `lua/`, including every plugin specification in `lua/plugins/`.
Keep that directory tree intact; do not replace it with a generated standalone configuration.
This bootstrap does not require a directory junction or administrator access.
If you use `NVIM_APPNAME` or `XDG_CONFIG_HOME`, use that application's actual configuration location instead.

### 3. Starship in PowerShell

Both tracked terminal defaults use PowerShell 7, so edit the profile shown by `$PROFILE` from a PowerShell 7 session. Windows PowerShell (`powershell.exe`) and PowerShell 7 (`pwsh.exe`) have separate profiles. Do not guess the profile path: `$PROFILE` handles Documents redirection (including OneDrive) and spaces in the path.

Back up an existing profile before editing, then create the parent directory and profile if needed and open the actual file:

```powershell
New-Item -ItemType Directory -Force -Path (Split-Path -Parent $PROFILE) | Out-Null
if (Test-Path -LiteralPath $PROFILE) {
    Copy-Item -LiteralPath $PROFILE -Destination "$PROFILE.bak"
}
if (-not (Test-Path -LiteralPath $PROFILE)) {
    New-Item -ItemType File -Path $PROFILE | Out-Null
}
notepad $PROFILE
```

Preserve unrelated profile content. Add this dot-source line to `$PROFILE` (replace `<repo-root>` with your clone path):

```powershell
. "<repo-root>\windows\config\powershell\profile.ps1"
```

If `$PROFILE` already contains a direct Starship initialization such as `Invoke-Expression (& starship init powershell)`, remove or replace that old line; do not keep it alongside the shared profile or initialize Starship twice. The shared repository profile sets `STARSHIP_CONFIG` to the tracked `<repo-root>\shared\config\starship\starship.toml` using a resolved, normalized path, then initializes the prompt. PowerShell loads `$PROFILE` on startup, and that dot-source line loads the repository profile. Setting `STARSHIP_CONFIG` by itself does not initialize the prompt; `$HOME\.starship_profile.ps1` is not loaded automatically.

The environment variable is set by the shared repository profile every time that profile runs; do not set it as a separate persistent Windows environment variable. You can dot-source the shared profile once for immediate testing, but that does not replace the `$PROFILE` line or prove startup loading:

```powershell
. "<repo-root>\windows\config\powershell\profile.ps1"
```

If startup reports that scripts cannot be loaded, run this in the affected shell to inspect execution policies by scope:

```powershell
Get-ExecutionPolicy -List
```

Follow your machine's policy; do not bypass organization restrictions.

### 4. Herdr

Herdr reads `windows\config\herdr\config.toml` directly from this clone; there is no AppData copy or TOML include.
The config explicitly selects PowerShell 7 for new interactive panes:

```toml
[terminal]
default_shell = "pwsh.exe"
```

This is a Windows-specific executable setting. Previously, the macOS Home Manager setup also links this shared config; now Herdr's configuration is separated into `windows/config/herdr/config.toml` and `unix/config/herdr/config.toml` so that each operating system configures its own default shell cleanly.

`default_shell` accepts the executable name or path, not a command plus arguments; do not add a `[shell]` table or `program`/`args` fields. Herdr's Windows fallback to `powershell.exe` applies only when no explicit default is configured; this config requires `pwsh.exe` to be installed and on `PATH`.

One-time manual setup for Herdr: first validate the absolute config path, then resolve it and set both scopes. The `throw` prevents either environment value from changing when the file is missing:

```powershell
$configPath = '<repo-root>\windows\config\herdr\config.toml'
if (-not (Test-Path -LiteralPath $configPath -PathType Leaf)) {
    throw "Herdr config file not found: $configPath"
}
$configPath = (Resolve-Path -LiteralPath $configPath -ErrorAction Stop).Path
[Environment]::SetEnvironmentVariable('HERDR_CONFIG_PATH', $configPath, 'User')
$env:HERDR_CONFIG_PATH = $configPath
```

After changing the path, restart/reopen Herdr so its server inherits the new value, then create a new pane. Existing panes keep their original shell and environment. For TOML changes after Herdr is running with the correct environment, run `herdr server reload-config` and create a new pane. Do not kill arbitrary processes or reset sessions.

---

## Verification

### Check Herdr config selection

Check Herdr's config selection separately from its shell and profile:

```powershell
$env:HERDR_CONFIG_PATH
[Environment]::GetEnvironmentVariable('HERDR_CONFIG_PATH', 'User')
Test-Path -LiteralPath $env:HERDR_CONFIG_PATH
Get-Content -LiteralPath $env:HERDR_CONFIG_PATH
herdr --help
```

Both environment values should name this clone's `windows\config\herdr\config.toml`, the path test should return `True`, and the file should show the `[terminal]` setting above. Those checks prove which file exists and is selected; they do not prove which shell or PowerShell profile a pane is running.

If Herdr shows a yellow config warning, check the displayed warning and the TOML section: `[shell]` with `program`/`args` is unsupported; use `[terminal]` with `default_shell`. Do not rely on the fallback to `powershell.exe` while the explicit `pwsh.exe` setting is present.

### Verify WezTerm's default

Fully close and reopen WezTerm, then use a fresh **standalone WezTerm default tab**—not a Herdr pane and not a shell you launched manually—to prove its configured default.
Run:

```powershell
$PSVersionTable.PSVersion
(Get-Process -Id $PID).Path
$PROFILE
Get-Content -LiteralPath $PROFILE
$env:STARSHIP_CONFIG
Test-Path -LiteralPath $env:STARSHIP_CONFIG
Get-Command starship
Get-Command ls, clear
ls
clear
```

Expect PowerShell 7.x, a process path ending in `pwsh.exe`, and `$PROFILE` to show the actual PowerShell 7 startup file (possibly under OneDrive-redirected Documents). Its contents should include the dot-source line to this clone's `windows\config\powershell\profile.ps1`. `STARSHIP_CONFIG` should be the normalized path to this clone's `shared\config\starship\starship.toml`, and `Test-Path` should return `True`. `Get-Command starship` should find the executable; `Get-Command` should show `ls` and `clear` as aliases for `Get-ChildItem` and `Clear-Host`. `ls` lists files and `clear` clears the terminal. The prompt should show the configured directory and arrow, plus Git information when the current directory is inside a Git repository.

### Verify Herdr's default pane

After Herdr has inherited the configured User environment, create a **fresh interactive Herdr pane**. Do not run `pwsh.exe` manually to test Herdr's default. Check both the selected config and the actual process/profile:

```powershell
$env:HERDR_CONFIG_PATH
[Environment]::GetEnvironmentVariable('HERDR_CONFIG_PATH', 'User')
Test-Path -LiteralPath $env:HERDR_CONFIG_PATH
Get-Content -LiteralPath $env:HERDR_CONFIG_PATH
$PSVersionTable.PSVersion
(Get-Process -Id $PID).Path
$PROFILE
Get-Content -LiteralPath $PROFILE
$env:STARSHIP_CONFIG
Test-Path -LiteralPath $env:STARSHIP_CONFIG
Get-Command starship
Get-Command ls, clear
```

The selected and User config paths should point to this clone's Herdr TOML and its `Test-Path` should return `True`; inspect that TOML for `[terminal]` and `default_shell = "pwsh.exe"`. Independently, expect PowerShell 7.x, a process path ending in `pwsh.exe`, the actual `$PROFILE` dot-sourcing this clone's shared PowerShell profile, and a normalized `STARSHIP_CONFIG` path to the tracked Starship TOML with its path test returning `True`. The prompt should be visible and configured; Git details appear only inside a repository. A valid config path or inherited environment value alone does not prove the pane's shell, profile, or prompt initialization.

If changing Herdr's TOML while its server is already running, `herdr server reload-config` reloads configuration; create a new pane to use the changed default. Existing panes retain their old shell. If the User environment path changed, restart Herdr itself first so its server receives that value.

### Neovim Verification

Launch `nvim` with network access for the first plugin installation.
Confirm there is no `module 'vim_config' not found` error and the Rose Pine Moon theme loads.
Use `:Lazy` to check plugin installation, `:checkhealth` to diagnose missing tools, and Space followed by `e`, `f`, or `s` for the file browser, file picker, or text search.
