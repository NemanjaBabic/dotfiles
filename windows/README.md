# Windows Setup (WezTerm, Starship, Neovim, and Herdr)

This guide starts with a fresh Windows machine using default settings, with no tools or dotfiles configured.
Windows uses the shared application configs (`shared/`) and Windows-specific configs (`windows/`) directly, not the macOS Nix setup.
Do not run `unix/bootstrap.sh` or `unix/rebuild.sh` on Windows.

## Prerequisites

Install these tools first; the bootstrap script configures them but does not install them:

- [PowerShell 7](https://learn.microsoft.com/en-us/powershell/scripting/install/installing-powershell-on-windows), separate from the built-in Windows PowerShell.
- [WezTerm](https://wezterm.org/install/windows.html) and [Herdr](https://herdr.dev/docs/install/).
- [Starship](https://starship.rs/guide/) and a [current stable Neovim](https://github.com/neovim/neovim/blob/master/INSTALL.md#install-from-download) (0.10 or newer).
- [Git](https://git-scm.com/downloads/win), [ripgrep](https://github.com/BurntSushi/ripgrep#installation), and [fd](https://github.com/sharkdp/fd#installation).
- **Hack Nerd Font** from [Nerd Fonts](https://www.nerdfonts.com/font-downloads): extract the download and install the font files so WezTerm can display prompt and plugin icons.

Enable installers' `PATH` options where available; for tools installed from archives, add their executable directories to your Windows User `PATH`.
Ensure `pwsh.exe`, `wezterm`, `herdr`, `starship`, `nvim`, `git`, `rg`, and `fd` are discoverable. Git is needed for plugin installation, ripgrep for text search, and fd for file picking. Herdr's explicit default requires `pwsh.exe` on `PATH`.
After installation and PATH changes, open a new **PowerShell 7** session (launch `pwsh.exe`, not `powershell.exe`) and confirm:

```powershell
Get-Command pwsh, wezterm, herdr, starship, nvim, git, rg, fd
```

Clone the repository to a permanent location and enter it:

```powershell
git clone https://github.com/NemanjaBabic/dotfiles.git "$HOME\dotfiles"
Set-Location "$HOME\dotfiles"
```

The configs load files directly from this clone, so keep it in place. In the manual steps below, `<repo-root>` means this clone's absolute path.

The tracked WezTerm config starts Windows tabs, windows, and splits in `C:\Git`. Create that directory before launching WezTerm:

```powershell
New-Item -ItemType Directory -Force -Path 'C:\Git' | Out-Null
```

If you cannot create that directory or prefer another location, change `git_dir` in `shared/config/wezterm/wezterm.lua` to an existing directory first.

Default Windows execution policy can block the bootstrap and startup profile. Inspect it from PowerShell 7:

```powershell
Get-ExecutionPolicy -List
```

On a personal, unmanaged machine, after reviewing the repository scripts, allow local scripts for your user if needed:

```powershell
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
```

Follow your machine's policy; do not bypass organization restrictions.

---

## Automated Setup (Recommended)

After completing the prerequisites, run this from the clone in a PowerShell 7 session:

```powershell
& ".\windows\bootstrap-windows.ps1"
```

The script automatically:
1. Creates `$HOME\.wezterm.lua` with `return dofile("<repo-root>/shared/config/wezterm/wezterm.lua")` (with forward slashes for Lua).
2. Creates `$env:LOCALAPPDATA\nvim\init.lua` with `dofile("<repo-root>/shared/config/nvim/init.lua")`, including its parent directory.
3. Creates `$PROFILE` and its directory, with a line dot-sourcing `<repo-root>\windows\config\powershell\profile.ps1`.
4. Validates that `<repo-root>\windows\config\herdr\config.toml` exists, and sets `HERDR_CONFIG_PATH` for both the current process and the Windows User environment scope.
5. Verifies prerequisite tools on `PATH` and reports missing dependencies.

It is safe to re-run. As a safety net for existing personal configs, differing WezTerm and Neovim entry files are backed up to `.wezterm.lua.bak` and `init.lua.bak`; an existing profile is backed up to `$PROFILE.bak` before the dot-source line is appended, preserving unrelated content. A profile that directly initializes Starship is left unchanged with instructions for manual setup to avoid initializing the prompt twice.

After setup, close the setup shell and launch WezTerm and Herdr so their new PowerShell sessions load the profile and environment. Continue with [Verification](#verification).

---

## Manual Walkthrough (Fallback)

After completing the prerequisites, follow these steps if you prefer to configure your environment manually instead of running `windows/bootstrap-windows.ps1`.
No configuration files need to exist beforehand. If you already have personal configs, back them up before editing and preserve unrelated profile content.

### 1. WezTerm

Create `$HOME\.wezterm.lua` to load the shared WezTerm configuration (replace `<repo-root>` with the absolute path using forward slashes):

```lua
return dofile("<repo-root>/shared/config/wezterm/wezterm.lua")
```

The tracked WezTerm config sets its Windows default command to `pwsh.exe -NoLogo`;
because it does not use `-NoProfile`, PowerShell loads its normal startup profile. The default shell on other platforms is unchanged.

### 2. Neovim

Create the default Windows configuration directory, `$env:LOCALAPPDATA\nvim`, and put this in `$env:LOCALAPPDATA\nvim\init.lua` (replace `<repo-root>` with the absolute path using forward slashes):

```lua
dofile("<repo-root>/shared/config/nvim/init.lua")
```

The repository's entry point adds its own directory to Neovim's runtime path before loading modules.
Its three `require` calls intentionally load settings, plugins, and keybindings from `lua/`, including every plugin specification in `lua/plugins/`.
Keep that directory tree intact; do not replace it with a generated standalone configuration.
This bootstrap does not require a directory junction or administrator access.
If you use `NVIM_APPNAME` or `XDG_CONFIG_HOME`, use that application's actual configuration location instead.

### 3. Starship in PowerShell

Both tracked terminal defaults use PowerShell 7, so create the profile shown by `$PROFILE` from a PowerShell 7 session. Windows PowerShell (`powershell.exe`) and PowerShell 7 (`pwsh.exe`) have separate profiles. Do not guess the profile path: `$PROFILE` handles Documents redirection (including OneDrive) and spaces in the path.

Create the parent directory and profile, then open the actual file. The backup check is a safety net if a profile already exists:

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

Add this dot-source line to `$PROFILE`, save the file, and close Notepad (replace `<repo-root>` with your clone path):

```powershell
. "<repo-root>\windows\config\powershell\profile.ps1"
```

The repository profile sets `STARSHIP_CONFIG` to the tracked `<repo-root>\shared\config\starship\starship.toml` using a resolved, normalized path, then initializes the prompt. PowerShell loads `$PROFILE` on startup, and that dot-source line loads the repository profile. Setting `STARSHIP_CONFIG` by itself does not initialize the prompt; `$HOME\.starship_profile.ps1` is not loaded automatically.

If you have a personal profile that already contains direct Starship initialization such as `Invoke-Expression (& starship init powershell)`, replace that line with the dot-source line above; do not initialize Starship twice.

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

This is a Windows-specific executable setting. macOS uses `unix/config/herdr/config.toml`, which allows Herdr to fall back to the user's login shell.

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

Launch Herdr after setting the path so its server inherits the configured value, then create a new pane. If Herdr was already running, fully close and reopen it first; existing panes keep their original shell and environment. For TOML changes after Herdr is running with the correct environment, run `herdr server reload-config` and create a new pane. Do not kill arbitrary processes or reset sessions.

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
