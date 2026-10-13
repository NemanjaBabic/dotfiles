# Shared Configurations

This directory contains application configurations that are identical across platforms (macOS/Unix and Windows).

## What lives here

- **`config/nvim/`**: Neovim configuration (`init.lua`, plugin specifications, and lazy-lock). Neovim uses Lua and works identically on macOS and Windows without requiring OS-specific branches.
- **`config/wezterm/`**: WezTerm terminal configuration (`wezterm.lua`). WezTerm is configured via Lua and detects the host operating system dynamically at runtime using `wezterm.target_triple` (e.g. selecting `pwsh.exe -NoLogo` on Windows while preserving the platform default on macOS/Linux).
- **`config/starship/`**: Starship cross-shell prompt configuration (`starship.toml`). Starship configuration is platform-agnostic TOML.
- **`AGENTS.md`, `CLAUDE.md`**: Global coding agent policies and guidelines. macOS Home Manager links them to `~/.claude/CLAUDE.md`, `~/.codex/AGENTS.md`, and `~/.config/opencode/AGENTS.md`; the Windows bootstrap links `AGENTS.md` to `~/.copilot/copilot-instructions.md`.
- **`.claude/`**: Shared settings for Claude Code (`settings.json`).
- **`.copilot/`**: Shared settings for GitHub Copilot CLI (`settings.json`).
- **`.pi/agent/`**: Shared configuration for the Pi coding agent, including themes (`rose-pine-moon`), extensions (Calm, terminal-status-title), models (`models.json`), and settings (`settings.json`).

## Why Herdr configuration is not shared

Unlike WezTerm and Neovim (which use Lua and can evaluate OS conditionals at runtime) or Starship (which uses platform-agnostic options), [Herdr](https://herdr.dev) uses a static TOML configuration file (`config.toml`).

Herdr's `[terminal]` section configures `default_shell`:
- On Windows, it requires `default_shell = "pwsh.exe"`.
- On macOS/Unix, `pwsh.exe` does not exist; `default_shell` is omitted so Herdr falls back to the user's login shell (`$SHELL`, typically `/bin/zsh`).

Because Herdr's static TOML does not support OS conditionals, each platform has its own configuration:
- `unix/config/herdr/config.toml` (macOS/Unix)
- `windows/config/herdr/config.toml` (Windows)
