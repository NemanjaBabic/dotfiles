#!/usr/bin/env bash
# Check platform-specific shell selection without launching WezTerm.
set -eu

# shellcheck source=tests/lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

LUA_BIN=${LUA_BIN:-lua}
command -v "$LUA_BIN" >/dev/null 2>&1 || fail "Lua runtime not found (set LUA_BIN)"

export DOTFILES_TEST_ROOT="$ROOT"
"$LUA_BIN" -e "$(cat <<'LUA'
local config_path = os.getenv("DOTFILES_TEST_ROOT") .. "/shared/config/wezterm/wezterm.lua"
for _, triple in ipairs({
    "x86_64-pc-windows-msvc",
    "aarch64-apple-darwin",
    "x86_64-unknown-linux-gnu",
}) do
    package.loaded.wezterm = {
        target_triple = triple,
        config_builder = function() return {} end,
        font = function(name) return name end,
        on = function() end,
        action = setmetatable({}, { __index = function(_, k) return function(...) return k end end }),
    }
    local config = dofile(config_path)
    if triple:find("windows", 1, true) then
        assert(type(config.default_prog) == "table", "Windows must select PowerShell")
        assert(#config.default_prog == 2, "Windows must keep profile loading enabled")
        assert(config.default_prog[1] == "pwsh.exe", "Windows must launch PowerShell 7")
        assert(config.default_prog[2] == "-NoLogo", "Windows must suppress the startup logo")
        assert(config.default_cwd == "C:\\Git", "Windows must retain its default working directory")
        assert(type(config.keys) == "table" and #config.keys == 4, "Windows must retain its custom keybindings")
    else
        assert(config.default_prog == nil, "Other platforms must retain their default shell")
    end
    assert(config.color_scheme == "rose-pine-moon", "Shared appearance must be preserved")
end
LUA
)" || fail "WezTerm platform-specific shell selection"

pass "WezTerm selects PowerShell with profiles on Windows only"
