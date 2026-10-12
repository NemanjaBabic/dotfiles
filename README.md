# dotfiles

<p align="center">
  <a href="https://discord.gg/Wsy2NpnZDu"
    ><img
      alt="Discord"
      src="https://img.shields.io/discord/1439901831038763092?style=flat-square&label=discord"
  /></a>
</p>

Watch the walkthrough: https://youtu.be/5N-okeDdIuI

My personal Mac setup, managed with nix-darwin and home-manager.
One repo, one command, and a fresh Mac ends up configured the same way every time.

## Contributing / Using This Repo

These are my personal dotfiles, shared publicly so people can read them, learn from them, and fork them freely.
Feature requests and pull requests are not accepted here, and PRs are auto-closed.
If you find a bug, please open a GitHub Issue using the bug report template.

## What you get

Running the switch builds:

- System settings (dark mode, key repeat, dock, Finder, trackpad)
- Homebrew apps (casks and CLI tools)
- Nix user packages (ripgrep, fd, fzf, jq, lazygit, Neovim, Hack Nerd Font)
- Shell (zsh, aliases, starship prompt)
- Editor (Neovim config with the rose-pine moon theme)
- Terminal (WezTerm config with the rose-pine moon theme and dimmed unfocused windows)
- Agent configs (Claude, Codex, opencode all share one AGENTS.md)
- Optional Pi theme and local extensions, generic UI settings and model overrides, plus two deliberately pinned third-party Pi packages

## Prerequisites

- Apple Silicon Mac, by default.
- Intel Mac: change one line.
  In `configuration.nix`, set `nixpkgs.hostPlatform = "x86_64-darwin";` (the comment right there tells you the same thing).

## Fresh-machine setup

On a brand new Mac, from a bare clone of this repo:

```sh
git clone https://github.com/kunchenguid/dotfiles.git
cd dotfiles
```

Before you run it: review "Make it yours" below.
Change the host label or CPU architecture if needed, and read the Homebrew cleanup warning.
`bootstrap.sh` applies the config to your machine, so do this first.

```sh
./bootstrap.sh
```

`bootstrap.sh` does four things, in order:

1. Installs Determinate Nix, if it isn't already installed.
2. Symlinks this repo to `~/.dotfiles`.
   This has to happen before the first build, because `home.nix` points at config files through `~/.dotfiles`.
3. Checks the `user` configured in `flake.nix` against your actual macOS username, and offers to fix it for you if they differ.
4. Runs the first `darwin-rebuild switch`.
   It fetches the `darwin-rebuild` tool from the nix-darwin 26.05 release branch, then applies this repo's locked flake config.

After that, `darwin-rebuild` exists and you're on the normal workflow below.

### Validate without applying

Once Nix is installed (`bootstrap.sh` step 1 handles that), you can check that the config builds without touching your system - handy when you have edited something:

```sh
nix flake check --no-build
nix build .#darwinConfigurations.mac.system --dry-run
```

If you renamed the host label in "Make it yours", substitute your label for `mac` in these commands.

## Windows setup (WezTerm, Starship, Neovim, and Herdr)

Windows uses the shared application configs directly, not the macOS Nix setup.
Do not run `bootstrap.sh` or `rebuild.sh` on Windows.
The examples below assume this repo is at `C:\Git\dotfiles`; adjust that path if needed.

### Prerequisites

Install WezTerm, Starship, a current stable Neovim (0.10 or newer), Git, ripgrep, and fd.
Git is needed for plugin installation, ripgrep for text search, and fd for file picking.
Make sure `starship`, `nvim`, `git`, `rg`, and `fd` are available on your shell's `PATH`.
Install **Hack Nerd Font** from [Nerd Fonts](https://www.nerdfonts.com/font-downloads) so WezTerm can use the configured font and display prompt and plugin icons.
The Herdr bootstrap below only configures its path; it does not require Herdr to be installed.
To use Herdr, install it using the [official installation instructions](https://herdr.dev/docs/install/).

### WezTerm

Keep this bootstrap in `$HOME\.wezterm.lua`:

```lua
return dofile("C:/Git/dotfiles/home/.config/wezterm/wezterm.lua")
```

The shared config launches PowerShell 7 (`pwsh.exe -NoLogo`) by default on Windows, with profile loading enabled.
Other platforms keep their default shell.

### Neovim

Back up any existing Neovim configuration before replacing its entry point.
For the default Windows configuration location, put this in `$env:LOCALAPPDATA\nvim\init.lua`
(create the `nvim` directory if it does not exist):

```lua
dofile("C:/Git/dotfiles/home/.config/nvim/init.lua")
```

The repository's entry point adds its own directory to Neovim's runtime path before loading modules.
Its three `require` calls intentionally load settings, plugins, and keybindings from `lua/`, including every plugin specification in `lua/plugins/`.
Keep that directory tree intact; do not replace it with a generated standalone configuration.
This bootstrap does not require a directory junction or administrator access.
If you use `NVIM_APPNAME` or `XDG_CONFIG_HOME`, use that application's actual configuration location instead.

### Starship in PowerShell

Configure the profile for the PowerShell edition actually launched by your terminal.
With the repository defaults, both WezTerm and Herdr use PowerShell 7 (`pwsh.exe`), so
configure the PowerShell 7 profile. Windows PowerShell (`powershell.exe`) and PowerShell 7
have separate profiles; run `$PROFILE` in the shell to find the actual startup file to edit.
If you intentionally switch either terminal to the other edition, configure that edition's
profile too.
Initializing PowerShell does not configure a Command Prompt session.

Create the parent directory and profile if they do not already exist:

```powershell
New-Item -ItemType Directory -Force -Path (Split-Path -Parent $PROFILE) | Out-Null
if (-not (Test-Path -LiteralPath $PROFILE)) {
    New-Item -ItemType File -Path $PROFILE | Out-Null
}
notepad $PROFILE
```

Add this line to that shell's actual `$PROFILE`, preserving any unrelated existing settings:

```powershell
. "C:\Git\dotfiles\home\.config\powershell\profile.ps1"
```

The shared profile sets `STARSHIP_CONFIG` relative to its own location and initializes Starship's PowerShell prompt.
PowerShell automatically loads `$PROFILE` on startup; the repository's profile is only loaded through the dot-source line above.
`$HOME\.starship_profile.ps1` is not loaded automatically, and setting `STARSHIP_CONFIG` alone does not activate the prompt.
Replace any older Starship initialization in your profile rather than initializing it twice.
If startup reports that scripts cannot be loaded, run this in the affected shell to inspect execution policies by scope:

```powershell
Get-ExecutionPolicy -List
```

Follow your machine's policy; do not bypass organization restrictions.

### Herdr

The bootstrap points Herdr directly at the tracked config in this clone; Git remains the
single source of truth, with no AppData copy or TOML include. From PowerShell, run:

```powershell
& "C:\Git\dotfiles\bootstrap-herdr.ps1"
```

Replace the example clone path if needed. The script resolves `home\.config\herdr\config.toml`
relative to its own location, so clones in other directories (including paths with spaces)
work; moving the clone requires running the bootstrap again.

Running it with `&` sets `HERDR_CONFIG_PATH` for the current PowerShell session as well as
the Windows User environment for future processes. Running it in an isolated
`powershell -File` process can persist the User value, but cannot update the parent
PowerShell process. Existing terminals and Herdr processes must be restarted to inherit
the new environment value.

Verify the selected path and ask Herdr to show its resolved config path:

```powershell
$env:HERDR_CONFIG_PATH
Test-Path -LiteralPath $env:HERDR_CONFIG_PATH
herdr --help
```

Herdr may write changes to the selected config, including `onboarding = false` after
onboarding and changes made through settings. Because this file is in the repository,
review `git diff` before committing; do not assume it is read-only.

On Windows, Herdr prefers `pwsh.exe` on `PATH`, then falls back to `powershell.exe`.
Initialize Starship in the profile for the shell Herdr actually launches. With the repo
defaults that is PowerShell 7; do not hardcode a shell in the shared cross-platform
Herdr TOML. If you intentionally switch Herdr to another shell edition, configure that
edition's profile as well.

### Verify

Fully restart WezTerm and check these in its new default tab (or the PowerShell edition you intentionally selected), without manually sourcing the shared profile:

```powershell
$PSVersionTable.PSVersion
$PROFILE
$env:STARSHIP_CONFIG
Test-Path -LiteralPath $env:STARSHIP_CONFIG
Get-Command ls, clear, starship
ls
clear
```

`$PSVersionTable` should identify PowerShell. `STARSHIP_CONFIG` should point to this repo's `home\.config\starship\starship.toml`,
and `Test-Path` should return `True`, confirming the profile ran at startup.
`Get-Command` should show `ls` and `clear` as aliases for `Get-ChildItem` and `Clear-Host`, and find the Starship executable.
`ls` should list files and `clear` should clear the terminal.
The prompt should show the configured directory and arrow, plus Git information inside a repository; finding `starship` alone does not confirm prompt initialization.
If these checks fail, check startup errors, the dot-source line in the displayed `$PROFILE`, and the execution policies above.

Launch `nvim` with network access for the first plugin installation.
Confirm there is no `module 'vim_config' not found` error and the Rose Pine Moon theme loads.
Use `:Lazy` to check plugin installation, `:checkhealth` to diagnose missing tools,
and Space followed by `e`, `f`, or `s` for the file browser, file picker, or text search.

## Daily use

Edit the config files in place, then apply:

```sh
./rebuild.sh
```

That's it.
No separate build-and-copy step.

## Make it yours

This repo is mine.
If you clone it, review these before you run `bootstrap.sh`:

- **Username**: run `./bootstrap.sh` (it detects your macOS username and offers to set it) OR change the single `user = "kunchen"` line in `flake.nix`.
  Everything else (`configuration.nix`, `home.nix`, home directory paths) is threaded from that one variable.
- **Host label** `"mac"`, in three places: `flake.nix` (the `darwinConfigurations."mac"` name), `rebuild.sh:5` (the `#mac` at the end of the flake reference), and `bootstrap.sh`'s first-switch command (also `#mac`).
  All three have to match.
- **CPU architecture**, `hostPlatform` in `configuration.nix` (see Prerequisites above).

**Git identity:** this config deliberately does not set your git name or email.
Git will stop your first commit and tell you to set them (`git config --global user.name "Your Name"` and `git config --global user.email you@example.com`).
If you'd rather manage that declaratively, add this back to `home.nix` with your own identity:

```nix
programs.git = {
  enable = true;
  settings.user = {
    name = "Your Name";
    email = "you@example.com";
  };
};
```

**Homebrew cleanup warning:** `configuration.nix` sets `homebrew.onActivation.cleanup = "zap"`.
That means every time you switch, Homebrew removes any package or cask on your machine that isn't listed in the `brews` and `casks` arrays in `configuration.nix`.
If you already have Homebrew stuff installed that isn't in that list, the first switch will uninstall it.
Read through `brews` and `casks` before you run `bootstrap.sh` or `rebuild.sh` for the first time, and add anything you want to keep.

**About `herdr`:** it's in the `brews` list.
It's a real public Homebrew formula (`brew info herdr` finds it in homebrew-core, no tap needed), so it will install fine.
If you don't use it, just remove it from `brews` in your copy.

**Heads-up:**

- `home/AGENTS.md` is my personal agent policy, and `home.nix` installs it for Claude, Codex, and opencode.
  If you clone this repo, you'd silently inherit my agent instructions - edit or delete `home/AGENTS.md` if you don't want that.
- The `cc` and `co` shell aliases in `home.nix` are high-agency shortcuts: `claude --dangerously-skip-permissions` and `codex --full-auto`.
  They're convenient for me, but know what they do before you use them.

## Repo tour

- `flake.nix` - the entry point.
  Wires up nixpkgs, nix-darwin, home-manager, and nix-homebrew, and declares the `mac` machine.
- `configuration.nix` - system-level config: macOS defaults, Homebrew.
- `home.nix` - user-level config: shell, packages, prompt, and the symlinks described below.
- `rebuild.sh` - re-applies the config after the first switch.
  Run this every time you make a change.
- `home/` - the actual config files that get symlinked into place; the sections below explain the shared symlink model and Pi's narrower selective setup.

## How the symlinks work

The files under `home/` are the real files - editing them here is editing your live config, no rebuild needed to see the change in your editor.
`home.nix` uses `mkOutOfStoreSymlink` to point paths like `~/.config/nvim` straight at `home/.config/nvim` in this repo, so the two never drift out of sync.
You only run `./rebuild.sh` when you change something that isn't just a symlinked file, like a package list or a system default.

## Optional Pi configuration

Pi is an opt-in CLI, not a dependency this repository vendors. Install it from its owner with the [official Pi instructions](https://pi.dev), for example:

```sh
npm install -g --ignore-scripts @earendil-works/pi-coding-agent
```

[Pi Launcher](https://github.com/kunchenguid/homebrew-tap) is also optional and installed from its owner, not declared by this config:

```sh
brew install --cask kunchenguid/tap/pi-launcher
```

Home Manager owns exactly two repository-authored Pi directories: `~/.pi/agent/themes` and `~/.pi/agent/extensions`. It also links `models.json` and `settings.json` as individual files. The local extension directory is for public, repository-authored extensions only - third-party package code never belongs there. Run `/reload` after editing a local extension or other Pi resources. The terminal-title extension shows a spinner while Pi is working, then a completion mark with the session name or current directory. The `rose-pine-moon` theme was authored clean-room from the public [Rosé Pine Moon palette](https://rosepinetheme.com/palette) and Pi's [public theme schema](https://raw.githubusercontent.com/earendil-works/pi/main/packages/coding-agent/src/modes/interactive/theme/theme-schema.json), not from a private or live theme file.

### Pi Calm

`home/.pi/agent/extensions/calm` is a standalone local Pi extension. Home Manager's existing global extensions-directory link makes Pi auto-load it without another declaration. `/calm` toggles a conversation-only presentation mode and is off by default. Its choice is stored locally in `~/.pi/agent/calm` (or the directory selected by `PI_CODING_AGENT_DIR`), not in this repository or Home Manager. Adapted from Firstmate under the bundled MIT license, Calm imports no Firstmate modules and has no Firstmate runtime dependency.

When enabled, Calm hides collapsed thinking and the call/result shells for Pi's seven built-in tools (`read`, `bash`, `edit`, `write`, `grep`, `find`, and `ls`) without leaving blank transcript rows. During an active run it replaces Pi's working row with a two-line animated blue-water, yellow-boat widget. `/calm` restores Pi's stock rendering and preserves the existing Ctrl+O tool-expansion choice.

Calm never changes prompts, tool execution, model context, session data, or ordering. `/share` and `/export` use the complete stock transcript. Generic custom tools, images, and unsupported Pi transcript classes deliberately remain visible because Pi has no safe general-purpose transcript filter. If a future Pi release no longer exports the exact collapsed-thinking rendering seam, Calm logs one diagnostic and leaves only that adapter disabled; all other behavior remains available.

Pi's package system declares two third-party sources in the linked global `settings.json`:

- `npm:pi-web-access@0.14.0` - the exact public npm release for web access.
- `npm:@ryan_nookpi/pi-extension-codex-fast-mode@0.2.6` - the exact public npm release from `ryan_nookpi`.

The versions are immutable pins, so Pi does not move them during package updates. Deliberate updates require a new source and security audit, followed by an explicit pin change in `home/.pi/agent/settings.json`. On Pi 0.82.0, global settings declarations install missing pinned packages automatically at startup. No one-time install command is required. Pi keeps the downloaded npm package trees in its own unmanaged `~/.pi/agent/npm` runtime directory, outside Home Manager and Git tracking.

Both packages execute with your full user permissions and must be trusted like any other executable code.

Home Manager deliberately does not manage `~/.pi/agent` itself, or Pi authentication, sessions, trust decisions, caches, npm/git package trees, or any other runtime state. The model overrides contain no credentials or endpoint settings, do not choose a default model, and only take effect after you authenticate Pi yourself. This remains an additive post-video layer: it does not install Pi, a launcher, or package source code into this repository.

## Notes

The first time you launch `nvim`, it bootstraps [lazy.nvim](https://github.com/folke/lazy.nvim) by cloning plugins from GitHub.
That needs network access once; after that it's offline.
Neovim and WezTerm both use the rose-pine moon theme.
Neovim keeps italics off and uses a transparent background on macOS, Windows, and WSL so it matches the terminal setup.

## License

This repo is licensed under MIT No Attribution.
See `LICENSE`.
