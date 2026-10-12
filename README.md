# dotfiles

<p align="center">
  <a href="https://discord.gg/Wsy2NpnZDu"
    ><img
      alt="Discord"
      src="https://img.shields.io/discord/1439901831038763092?style=flat-square&label=discord"
  /></a>
</p>

Watch the walkthrough: https://youtu.be/5N-okeDdIuI

Personal cross-platform dotfiles organized cleanly across operating systems and shared environments.

## Contributing / Using This Repo

These are my personal dotfiles, shared publicly so people can read them, learn from them, and fork them freely.
Feature requests and pull requests are not accepted here, and PRs are auto-closed.
If you find a bug, please open a GitHub Issue using the bug report template.

## Repository Structure

The repository is organized into three top-level directories so that platform-specific configurations and cross-platform shared configurations are clearly separated:

```
dotfiles/
├── shared/     # Cross-platform application configs identical across OSes (Neovim, WezTerm, Starship, Pi, AI agent policies)
├── unix/       # macOS & Nix setup (Nix-Darwin, Home Manager, bootstrap.sh, rebuild.sh)
└── windows/    # Windows setup (PowerShell 7 profile, Herdr config, bootstrap-windows.ps1)
```

### Directory Overview

- **[`shared/`](shared/README.md)**: Application configurations that work identically across macOS, Linux, and Windows without OS branching. Includes Neovim (`shared/config/nvim`), WezTerm (`shared/config/wezterm`), Starship prompt (`shared/config/starship`), Pi agent configurations (`shared/.pi/agent`), and shared AI agent instructions (`shared/AGENTS.md`, `shared/CLAUDE.md`).
- **[`unix/`](unix/README.md)**: Declarative macOS workstation management using [nix-darwin](https://github.com/LnL7/nix-darwin) and [home-manager](https://github.com/nix-community/home-manager). Contains `flake.nix`, `configuration.nix`, `home.nix`, `bootstrap.sh`, `rebuild.sh`, and the macOS Herdr config (`unix/config/herdr/config.toml`).
- **[`windows/`](windows/README.md)**: Windows workstation configuration for PowerShell 7 and terminal tools. Contains `bootstrap-windows.ps1` (an automated setup script), `windows/config/powershell/profile.ps1`, and the Windows Herdr config (`windows/config/herdr/config.toml`).

## Getting Started

- **macOS / Nix users**: Follow the **[macOS / Unix Setup Guide](unix/README.md)** to bootstrap your machine with `./unix/bootstrap.sh`.
- **Windows users**: Follow the **[Windows Setup Guide](windows/README.md)** to configure your environment automatically with `.\windows\bootstrap-windows.ps1`.
- **Shared configuration details**: See **[Shared Configurations](shared/README.md)** for details on common configs and symlink setups.

## License

This repo is licensed under MIT No Attribution.
See `LICENSE`.
