local wezterm = require("wezterm")
local act = wezterm.action

local config = wezterm.config_builder()

----------------------------------------------------------------------
-- Platform-specific defaults
----------------------------------------------------------------------
-- On Windows:
-- - use PowerShell as the default shell
-- - start new terminals in C:\Git
-- - define custom keybindings for new tabs/windows/splits
local is_windows = wezterm.target_triple:find("windows", 1, true) ~= nil
local git_dir = "C:\\Git"

if is_windows then
	config.default_prog = { "powershell.exe", "-NoLogo" }
	config.default_cwd = git_dir

	config.keys = {
		-- Open a new tab in C:\Git
		{
			key = "t",
			mods = "CTRL|ALT",
			action = act.SpawnCommandInNewTab({
				cwd = git_dir,
			}),
		},

		-- Open a new window in C:\Git
		{
			key = "n",
			mods = "CTRL|ALT",
			action = act.SpawnCommandInNewWindow({
				cwd = git_dir,
			}),
		},

		-- Split the current pane left/right
		{
			key = "h",
			mods = "CTRL|ALT",
			action = act.SplitHorizontal({
				domain = "CurrentPaneDomain",
				cwd = git_dir,
			}),
		},

		-- Split the current pane top/bottom
		{
			key = "v",
			mods = "CTRL|ALT",
			action = act.SplitVertical({
				domain = "CurrentPaneDomain",
				cwd = git_dir,
			}),
		},
	}
end

----------------------------------------------------------------------
-- Appearance
----------------------------------------------------------------------
-- Theme, font, and font sizing.
config.color_scheme = "rose-pine-moon"
config.font = wezterm.font("Hack Nerd Font")
config.font_size = 14.0

----------------------------------------------------------------------
-- Window transparency / backdrop
----------------------------------------------------------------------
-- Make the terminal slightly transparent.
-- Disable the Windows system backdrop effect so the appearance stays consistent.
config.window_background_opacity = 0.7
config.win32_system_backdrop = "Disable"

----------------------------------------------------------------------
-- Window and tab behavior
----------------------------------------------------------------------
-- Hide the tab bar when only one tab exists.
-- Keep normal resizable window borders.
config.hide_tab_bar_if_only_one_tab = true
config.window_decorations = "RESIZE"

----------------------------------------------------------------------
-- Unfocused window dimming
----------------------------------------------------------------------
-- When a WezTerm window is not focused:
-- - reduce text saturation/brightness
-- - slightly change background opacity
--
-- This makes the active window stand out visually.
local UNFOCUSED_FOREGROUND_TEXT_HSB = {
	hue = 1.0,
	saturation = 0.25,
	brightness = 0.45,
}

local UNFOCUSED_WINDOW_BACKGROUND_OPACITY = 0.62

-- Compare HSB tables by value rather than table identity.
-- get_config_overrides() returns a fresh table copy, so direct table
-- equality is not useful here.
local function same_text_hsb(actual, expected)
	if actual == nil or expected == nil then
		return actual == expected
	end

	return actual.hue == expected.hue
		and actual.saturation == expected.saturation
		and actual.brightness == expected.brightness
end

-- Update per-window overrides whenever focus changes.
wezterm.on("window-focus-changed", function(window)
	local overrides = window:get_config_overrides() or {}
	local text_hsb, opacity

	if not window:is_focused() then
		text_hsb = UNFOCUSED_FOREGROUND_TEXT_HSB
		opacity = UNFOCUSED_WINDOW_BACKGROUND_OPACITY
	end

	-- Avoid unnecessary writes, because repeatedly setting the same
	-- overrides can trigger redundant config reloads.
	if same_text_hsb(overrides.foreground_text_hsb, text_hsb)
		and overrides.window_background_opacity == opacity
	then
		return
	end

	overrides.foreground_text_hsb = text_hsb
	overrides.window_background_opacity = opacity
	window:set_config_overrides(overrides)
end)

----------------------------------------------------------------------
-- Mouse bindings
----------------------------------------------------------------------
config.mouse_bindings = {
	-- Hold Alt + left click to drag the entire WezTerm window.
	{
		event = { Down = { streak = 1, button = "Left" } },
		mods = "ALT",
		action = act.StartWindowDrag,
	},

	-- Hold Alt + middle click to close the current pane immediately.
	{
		event = { Down = { streak = 1, button = "Middle" } },
		mods = "ALT",
		action = act.CloseCurrentPane({ confirm = false }),
	},
}

return config