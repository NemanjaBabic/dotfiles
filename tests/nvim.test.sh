#!/usr/bin/env bash
# Check plugin initialization and bootstrap behavior without downloading plugins.
set -eu

# shellcheck source=tests/lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

LUA_BIN=${LUA_BIN:-lua}
command -v "$LUA_BIN" >/dev/null 2>&1 || fail "Lua runtime not found (set LUA_BIN)"

export DOTFILES_TEST_ROOT="$ROOT"
"$LUA_BIN" -e "$(cat <<'LUA'
local config_dir = os.getenv("DOTFILES_TEST_ROOT") .. "/home/.config/nvim"
local plugin_path = config_dir .. "/lua/plugin.lua"
local lazypath = "/test/data/lazy/lazy.nvim"
local exit_marker = {}
local original_exit = os.exit

for _, scenario in ipairs({ "installed", "clone_success", "clone_failure" }) do
    local cloned, echoed, waited, exited, prepended, configured = false, false, false, false, false, false
    vim = {
        v = { shell_error = 0 },
        uv = {
            fs_stat = function(path)
                assert(path == lazypath)
                return scenario == "installed" and {} or nil
            end,
        },
        fn = {
            stdpath = function(kind)
                assert(kind == "data")
                return "/test/data"
            end,
            system = function(args)
                assert(scenario ~= "installed")
                assert(table.concat(args, "\n") == table.concat({
                    "git", "clone", "--filter=blob:none",
                    "https://github.com/folke/lazy.nvim.git", "--branch=stable", lazypath,
                }, "\n"))
                cloned = true
                vim.v.shell_error = scenario == "clone_failure" and 1 or 0
                return "git clone diagnostic"
            end,
            fnamemodify = function(path, modifiers)
                assert(path == plugin_path, "Config path must come from the bootstrap module")
                assert(modifiers == ":p:h:h")
                return path:match("^(.*)/lua/plugin%.lua$")
            end,
            getchar = function()
                assert(echoed, "Display the clone error before waiting")
                waited = true
            end,
        },
        api = {
            nvim_echo = function(chunks, history, opts)
                assert(chunks[1][1] == "Failed to clone lazy.nvim:\n")
                assert(chunks[1][2] == "ErrorMsg")
                assert(chunks[2][1] == "git clone diagnostic")
                assert(chunks[2][2] == "WarningMsg")
                assert(chunks[3][1] == "\nPress any key to exit...")
                assert(history == true and next(opts) == nil)
                echoed = true
            end,
        },
        opt = {
            rtp = {
                prepend = function(_, path)
                    assert(path == lazypath)
                    prepended = true
                end,
            },
        },
    }
    package.loaded.lazy = {
        setup = function(spec, opts)
            assert(prepended, "Add lazy.nvim to runtimepath before setup")
            assert(spec == "plugins")
            assert(opts.lockfile == config_dir .. "/lazy-lock.json", "Use the repository lockfile")
            assert(opts.performance.rtp.reset == false, "Preserve the dofile bootstrap runtimepath")
            configured = true
        end,
    }
    os.exit = function(code)
        assert(code == 1 and waited, "Wait for a key before exiting with failure")
        exited = true
        error(exit_marker)
    end
    local ok, err = pcall(dofile, plugin_path)
    if scenario == "clone_failure" then
        assert(not ok and err == exit_marker)
        assert(cloned and echoed and waited and exited)
        assert(not prepended and not configured, "Do not initialize lazy.nvim after clone failure")
    else
        assert(ok, tostring(err))
        assert(cloned == (scenario == "clone_success"))
        assert(prepended and configured)
        assert(not echoed and not waited and not exited)
    end
end
os.exit = original_exit

local plugins = dofile(config_dir .. "/lua/plugins/git.lua")
assert(plugins[1][1] == "NeogitOrg/neogit")
assert(plugins[1].lazy == false, "Neogit must load on startup")
assert(type(plugins[1].opts) == "table" and next(plugins[1].opts) == nil,
    "Neogit must explicitly enable setup with empty options")

local navigation_plugins = dofile(config_dir .. "/lua/plugins/navigation.lua")
assert(navigation_plugins[1][1] == "stevearc/oil.nvim")
assert(navigation_plugins[1].lazy == false, "Oil must load on startup")
assert(navigation_plugins[1].opts.view_options.show_hidden,
    "Oil must continue showing hidden files")
LUA
)" || fail "Neovim plugin initialization and bootstrap"

pass "Neovim initializes Neogit, preserves runtimepath, uses the repository lockfile, and handles clone failures"
