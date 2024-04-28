local wezterm = require("wezterm")
local action = wezterm.action

local config = {}
-- Use config_builder object if possible
if wezterm.config_builder then
	config = wezterm.config_builder()
end

-- Settings
config.color_scheme = "Aardvark Blue"
config.font = wezterm.font_with_fallback({
	{ family = "0xProto Nerd Font", scale = 1 },
	{ family = "VictorMono Nerd Font", scale = 1 },
	{ family = "FantasqueSansMono Nerd Font", scale = 1 },
})
config.font_size = 16
config.window_background_opacity = 0.9
config.window_decorations = "RESIZE"
config.scrollback_lines = 5000
config.default_workspace = "home"
config.inactive_pane_hsb = {
	saturation = 0.3,
	brightness = 0.3,
}

-- Key bindings
config.leader = { key = "t", mods = "CTRL", timeout_milliseconds = 1000 }
config.keys = {
	{ key = "t", mods = "LEADER", action = action.SendKey({ key = "t", mods = "CTRL" }) },
	{ key = "c", mods = "LEADER", action = action.ActivateCopyMode },

	-- Panes
	{ key = "-", mods = "LEADER", action = action.SplitVertical({ domain = "CurrentPaneDomain" }) },
	{ key = "|", mods = "LEADER|SHIFT", action = action.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
	{ key = "h", mods = "LEADER", action = action.ActivatePaneDirection("Left") },
	{ key = "j", mods = "LEADER", action = action.ActivatePaneDirection("Down") },
	{ key = "k", mods = "LEADER", action = action.ActivatePaneDirection("Up") },
	{ key = "l", mods = "LEADER", action = action.ActivatePaneDirection("Right") },

	{ key = "x", mods = "LEADER", action = action.CloseCurrentPane({ confirm = true }) },

	{ key = "z", mods = "LEADER", action = action.TogglePaneZoomState },
	{ key = "r", mods = "LEADER", action = action.RotatePanes("Clockwise") },

	-- resizing panes
	{ key = "s", mods = "LEADER", action = action.ActivateKeyTable({ name = "resize_pane", one_shot = false }) },

	-- Tabs
	{ key = "n", mods = "LEADER", action = action.SpawnTab("CurrentPaneDomain") },
	{ key = "[", mods = "LEADER", action = action.ActivateTabRelative(-1) },
	{ key = "]", mods = "LEADER", action = action.ActivateTabRelative(1) },
	{ key = "t", mods = "LEADER", action = action.ShowTabNavigator },
	-- moving around tabs
	{ key = "m", mods = "LEADER", action = action.ActivateKeyTable({ name = "move_tab", one_shot = false }) },

	-- Workspaces
	{ key = "w", mods = "LEADER", action = action.ShowLauncherArgs({ flags = "FUZZY|WORKSPACES" }) },
}

for i = 1, 9 do
	table.insert(config.keys, {
		key = tostring(i),
		mods = "LEADER",
		action = action.ActivateTab(i - 1),
	})
end

config.key_tables = {
	resize_pane = {
		{ key = "h", action = action.AdjustPaneSize({ "Left", 1 }) },
		{ key = "j", action = action.AdjustPaneSize({ "Down", 1 }) },
		{ key = "k", action = action.AdjustPaneSize({ "Up", 1 }) },
		{ key = "l", action = action.AdjustPaneSize({ "Right", 1 }) },
		{ key = "Escape", action = "PopKeyTable" },
		{ key = "Enter", action = "PopKeyTable" },
	},
	move_tab = {
		{ key = "h", action = action.MoveTabRelative(-1) },
		{ key = "l", action = action.MoveTabRelative(1) },
		{ key = "Escape", action = "PopKeyTable" },
		{ key = "Enter", action = "PopKeyTable" },
	},
}

-- Tab bar by default looks ugly
config.use_fancy_tab_bar = false
config.status_update_interval = 1000
wezterm.on("update-right-status", function(window, pane)
	-- Workspace name
	local stat = window:active_workspace()

	if window:active_key_table() then
		stat = window:active_key_table()
	end
	if window:leader_is_active() then
		stat = "<Leader>"
	end

	-- current working directory
	local basename = function(s)
		return string.gsub(s, "(.*[/\\])(.*)", "%2")
	end
	-- current command name
	local cmd = basename(pane:get_foreground_process_name())

	local time = wezterm.strftime("%H:%M:%S")

	window:set_right_status(wezterm.format({
		{ Text = wezterm.nerdfonts.oct_table .. "  " .. stat },
		{ Text = " | " },
		{ Text = wezterm.nerdfonts.fa_code .. "  " .. cmd },
		{ Text = " | " },
		{ Text = wezterm.nerdfonts.md_clock .. "  " .. time },
	}))
end)

return config
