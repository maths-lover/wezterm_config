local wezterm = require "wezterm"
local action = wezterm.action

local home_dir = os.getenv "HOME"
local wallpaper_dir = home_dir .. "/Pictures/Wallpapers/"

-- wezterm.add_to_config_reload_watch_list(wallpaper_dir .. "wallpaper.png")

local config = {}
-- Use config_builder object if possible
if wezterm.config_builder then
  config = wezterm.config_builder()
end

-- Settings
config.default_prog = { "/bin/zsh", "-l" }
config.color_scheme = "Aardvark Blue"
local scheme = wezterm.color.get_builtin_schemes()["Aardvark Blue"]
config.font = wezterm.font_with_fallback {
  { family = "Cascadia Code", scale = 1 },
  { family = "MartianMono Nerd Font Propo", scale = 1 },
  { family = "0xProto Nerd Font", scale = 1 },
}
config.font_size = 12
config.line_height = 1.2
config.window_decorations = "RESIZE"
config.scrollback_lines = 5000
config.default_workspace = "home"
config.inactive_pane_hsb = {
  saturation = 0.7,
  brightness = 0.6,
}
config.window_padding = {
  left = "1cell",
  right = "1cell",
  top = 0,
  bottom = 0,
}
-- wallpaper setting
local dimmer = { brightness = 0.05 }
config.enable_scroll_bar = true
config.min_scroll_bar_height = "2cell"
config.colors = {
  scrollbar_thumb = scheme.ansi[13],
  split = scheme.ansi[5],
}
config.background = {
  {
    source = {
      File = wallpaper_dir .. "wallpaper.png",
    },
    repeat_x = "Mirror",
    vertical_align = "Middle",
    horizontal_align = "Center",
    hsb = dimmer,
    -- attachment = { Parallax = 0.1 },
    attachment = "Fixed",
  },
}

-- Docs and my own functions
wezterm.on("filter-last-command-output", function(window, pane)
  -- Retrieve current semantic zone
  local out_zone = pane:get_semantic_zones()
  -- Retrieve the current pane's text
  local text = pane:get_text_from_semantic_zone(out_zone["Output"])

  -- Create a temporary file to pass to the pager
  local name = os.tmpname()
  local f = io.open(name, "w+")
  f:write(text)
  f:flush()
  f:close()

  -- Open a new window running less and tell it to open the file
  window:perform_action(
    action.SpawnCommandInNewWindow {
      args = { "fzf", "<", name },
    },
    pane
  )

  -- Wait "enough" time for less to read the file before we remove it.
  -- The window creation and process spawn are asynchronous wrt. running
  -- this script and are not awaitable, so we just pick a number.
  --
  -- Note: We don't strictly need to remove this file, but it is nice
  -- to avoid cluttering up the temporary directory.
  wezterm.sleep_ms(1000)
  os.remove(name)
end)

-- Key bindings
config.leader = { key = "a", mods = "CTRL", timeout_milliseconds = 1000 }
config.keys = {
  { key = "a", mods = "LEADER", action = action.SendKey { key = "a", mods = "CTRL" } },
  { key = "c", mods = "LEADER", action = action.ActivateCopyMode },

  -- Panes
  { key = "-", mods = "LEADER", action = action.SplitVertical { domain = "CurrentPaneDomain" } },
  { key = "|", mods = "LEADER|SHIFT", action = action.SplitHorizontal { domain = "CurrentPaneDomain" } },
  { key = "h", mods = "LEADER", action = action.ActivatePaneDirection "Left" },
  { key = "j", mods = "LEADER", action = action.ActivatePaneDirection "Down" },
  { key = "k", mods = "LEADER", action = action.ActivatePaneDirection "Up" },
  { key = "l", mods = "LEADER", action = action.ActivatePaneDirection "Right" },

  { key = "x", mods = "LEADER", action = action.CloseCurrentPane { confirm = true } },

  { key = "z", mods = "LEADER", action = action.TogglePaneZoomState },
  { key = "r", mods = "LEADER", action = action.RotatePanes "Clockwise" },

  -- resizing panes
  { key = "s", mods = "LEADER", action = action.ActivateKeyTable { name = "resize_pane", one_shot = false } },

  -- Tabs
  { key = "n", mods = "LEADER", action = action.SpawnTab "CurrentPaneDomain" },
  { key = "[", mods = "LEADER", action = action.ActivateTabRelative(-1) },
  { key = "]", mods = "LEADER", action = action.ActivateTabRelative(1) },
  { key = "t", mods = "LEADER", action = action.ShowTabNavigator },
  -- moving around tabs
  { key = "m", mods = "LEADER", action = action.ActivateKeyTable { name = "move_tab", one_shot = false } },

  -- Workspaces
  { key = "w", mods = "LEADER", action = action.ShowLauncherArgs { flags = "FUZZY|WORKSPACES" } },

  -- switching panes easily
  { key = "p", mods = "LEADER", action = action.PaneSelect },

  -- Docs and my own functions keybindings if necessary
  { key = "E", mods = "CTRL", action = action.EmitEvent "filter-last-command-outputy" },
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
    { key = "h", action = action.AdjustPaneSize { "Left", 1 } },
    { key = "j", action = action.AdjustPaneSize { "Down", 1 } },
    { key = "k", action = action.AdjustPaneSize { "Up", 1 } },
    { key = "l", action = action.AdjustPaneSize { "Right", 1 } },
    { key = "Escape", action = "PopKeyTable" },
    { key = "Enter", action = "PopKeyTable" },
  },
  move_tab = {
    { key = "h", action = action.MoveTabRelative(-1) },
    { key = "l", action = action.MoveTabRelative(1) },
    { key = "Escape", action = "PopKeyTable" },
    { key = "Enter", action = "PopKeyTable" },
  },
  search_mode = {
    { key = "Enter", mods = "NONE", action = action.CopyMode "PriorMatch" },
    { key = "Escape", mods = "NONE", action = action.CopyMode "Close" },
    { key = "n", mods = "CTRL", action = action.CopyMode "NextMatch" },
    { key = "p", mods = "CTRL", action = action.CopyMode "PriorMatch" },
    { key = "r", mods = "CTRL", action = action.CopyMode "CycleMatchType" },
    { key = "u", mods = "CTRL", action = action.CopyMode "ClearPattern" },
    { key = "PageUp", mods = "NONE", action = action.CopyMode "PriorMatchPage" },
    { key = "PageDown", mods = "NONE", action = action.CopyMode "NextMatchPage" },
    { key = "UpArrow", mods = "NONE", action = action.CopyMode "PriorMatch" },
    { key = "DownArrow", mods = "NONE", action = action.CopyMode "NextMatch" },
  },
  copy_mode = {
    { key = "Enter", mods = "NONE", action = action.CopyMode "MoveToStartOfNextLine" },
    { key = "Escape", mods = "NONE", action = action.CopyMode "Close" },
    { key = "Space", mods = "NONE", action = action.CopyMode { SetSelectionMode = "Cell" } },
    { key = "$", mods = "NONE", action = action.CopyMode "MoveToEndOfLineContent" },
    { key = "$", mods = "SHIFT", action = action.CopyMode "MoveToEndOfLineContent" },
    { key = ",", mods = "NONE", action = action.CopyMode "JumpReverse" },
    { key = "0", mods = "NONE", action = action.CopyMode "MoveToStartOfLine" },
    { key = ";", mods = "NONE", action = action.CopyMode "JumpAgain" },
    {
      key = "C",
      mods = "SHIFT",
      action = action.CopyMode "ClearPattern",
    },
    { key = "F", mods = "NONE", action = action.CopyMode { JumpBackward = { prev_char = false } } },
    { key = "F", mods = "SHIFT", action = action.CopyMode { JumpBackward = { prev_char = false } } },
    { key = "G", mods = "NONE", action = action.CopyMode "MoveToScrollbackBottom" },
    { key = "G", mods = "SHIFT", action = action.CopyMode "MoveToScrollbackBottom" },
    { key = "H", mods = "NONE", action = action.CopyMode "MoveToViewportTop" },
    { key = "H", mods = "SHIFT", action = action.CopyMode "MoveToViewportTop" },
    { key = "L", mods = "NONE", action = action.CopyMode "MoveToViewportBottom" },
    { key = "L", mods = "SHIFT", action = action.CopyMode "MoveToViewportBottom" },
    { key = "M", mods = "NONE", action = action.CopyMode "MoveToViewportMiddle" },
    { key = "M", mods = "SHIFT", action = action.CopyMode "MoveToViewportMiddle" },
    { key = "O", mods = "NONE", action = action.CopyMode "MoveToSelectionOtherEndHoriz" },
    { key = "O", mods = "SHIFT", action = action.CopyMode "MoveToSelectionOtherEndHoriz" },
    { key = "T", mods = "NONE", action = action.CopyMode { JumpBackward = { prev_char = true } } },
    { key = "T", mods = "SHIFT", action = action.CopyMode { JumpBackward = { prev_char = true } } },
    { key = "V", mods = "NONE", action = action.CopyMode { SetSelectionMode = "Line" } },
    { key = "V", mods = "SHIFT", action = action.CopyMode { SetSelectionMode = "Line" } },
    { key = "^", mods = "NONE", action = action.CopyMode "MoveToStartOfLineContent" },
    { key = "^", mods = "SHIFT", action = action.CopyMode "MoveToStartOfLineContent" },
    { key = "b", mods = "NONE", action = action.CopyMode "MoveBackwardWord" },
    { key = "b", mods = "CTRL", action = action.CopyMode "PageUp" },
    { key = "c", mods = "CTRL", action = action.CopyMode "Close" },
    { key = "d", mods = "CTRL", action = action.CopyMode { MoveByPage = 0.5 } },
    { key = "e", mods = "NONE", action = action.CopyMode "MoveForwardWordEnd" },
    { key = "f", mods = "NONE", action = action.CopyMode { JumpForward = { prev_char = false } } },
    { key = "f", mods = "CTRL", action = action.CopyMode "PageDown" },
    { key = "g", mods = "NONE", action = action.CopyMode "MoveToScrollbackTop" },
    { key = "g", mods = "CTRL", action = action.CopyMode "Close" },
    { key = "h", mods = "NONE", action = action.CopyMode "MoveLeft" },
    { key = "j", mods = "NONE", action = action.CopyMode "MoveDown" },
    { key = "k", mods = "NONE", action = action.CopyMode "MoveUp" },
    { key = "l", mods = "NONE", action = action.CopyMode "MoveRight" },
    { key = "m", mods = "ALT", action = action.CopyMode "MoveToStartOfLineContent" },
    { key = "o", mods = "NONE", action = action.CopyMode "MoveToSelectionOtherEnd" },
    { key = "q", mods = "NONE", action = action.CopyMode "Close" },
    { key = "t", mods = "NONE", action = action.CopyMode { JumpForward = { prev_char = true } } },
    { key = "u", mods = "CTRL", action = action.CopyMode { MoveByPage = -0.5 } },
    { key = "v", mods = "NONE", action = action.CopyMode { SetSelectionMode = "Cell" } },
    { key = "v", mods = "CTRL", action = action.CopyMode { SetSelectionMode = "Block" } },
    { key = "w", mods = "NONE", action = action.CopyMode "MoveForwardWord" },
    {
      key = "y",
      mods = "NONE",
      action = action.Multiple { { CopyTo = "ClipboardAndPrimarySelection" }, { CopyMode = "Close" } },
    },
    { key = "PageUp", mods = "NONE", action = action.CopyMode "PageUp" },
    { key = "PageDown", mods = "NONE", action = action.CopyMode "PageDown" },
    { key = "End", mods = "NONE", action = action.CopyMode "MoveToEndOfLineContent" },
    { key = "Home", mods = "NONE", action = action.CopyMode "MoveToStartOfLine" },
    { key = "LeftArrow", mods = "NONE", action = action.CopyMode "MoveLeft" },
    { key = "RightArrow", mods = "NONE", action = action.CopyMode "MoveRight" },
    { key = "UpArrow", mods = "NONE", action = action.CopyMode "MoveUp" },
    { key = "DownArrow", mods = "NONE", action = action.CopyMode "MoveDown" },
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

  local time = wezterm.strftime "%H:%M:%S"

  window:set_right_status(wezterm.format {
    { Text = wezterm.nerdfonts.oct_table .. "  " .. stat },
    { Text = " | " },
    { Text = wezterm.nerdfonts.fa_code .. "  " .. cmd },
    { Text = " | " },
    { Text = wezterm.nerdfonts.md_clock .. "  " .. time },
  })
end)

config.mouse_bindings = {
  {
    event = { Down = { streak = 3, button = "Left" } },
    action = wezterm.action.SelectTextAtMouseCursor "SemanticZone",
    mods = "NONE",
  },
}

return config
