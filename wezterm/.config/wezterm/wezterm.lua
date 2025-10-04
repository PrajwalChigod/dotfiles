local wezterm = require("wezterm")
local config = wezterm.config_builder()

-- Catppuccin Mocha colors
local catppuccin = {
  blue = "#89b4fa",        -- Catppuccin blue for active tabs
  surface0 = "#313244",    -- Dark grey for inactive tabs
  surface1 = "#45475a",    -- Slightly lighter grey for hover
  overlay1 = "#7f849c",    -- Muted text for inactive tabs
  text = "#cdd6f4",        -- Bright text for active tabs
  base = "#1e1e2e",        -- Background
}

config.color_scheme = "Catppuccin Mocha (Gogh)"
config.font = wezterm.font("Monaspace Argon ExtraBold")
config.font_size = 15
config.window_decorations = "RESIZE"
config.enable_tab_bar = true
config.hide_tab_bar_if_only_one_tab = true
config.tab_bar_at_bottom = true
config.native_macos_fullscreen_mode = true
config.use_fancy_tab_bar = false
config.show_new_tab_button_in_tab_bar = false
config.colors = {
	background = "#000000",
	tab_bar = {
	    background = "#000000"
	}
}

-- Simple vertical bar for tab separator
local TAB_SEPARATOR = "│"

-- This function returns just the current directory name for the tab title
function tab_title(tab_info)
  local title = tab_info.tab_title
  -- if the tab title is explicitly set, take that
  if title and #title > 0 then
    return title
  end

  -- Get the current working directory from the active pane
  local cwd = tab_info.active_pane.current_working_dir
  if cwd then
    -- Extract just the directory name from the path
    local dir = cwd.file_path or cwd
    return string.match(dir, "([^/\\]+)/?$") or "~"
  end

  -- Fallback to pane title if no cwd available
  return tab_info.active_pane.title
end

wezterm.on(
  'format-tab-title',
  function(tab, tabs, panes, config, hover, max_width)
    local edge_background = '#000000'  -- Match your black background
    local background = catppuccin.surface0  -- Grey for inactive tabs
    local foreground = catppuccin.overlay1  -- Muted text for inactive tabs

    if tab.is_active then
      background = catppuccin.blue      -- Catppuccin blue for active tab
      foreground = catppuccin.base      -- Dark text on blue background
    elseif hover then
      background = catppuccin.surface1  -- Slightly lighter grey for hover
      foreground = catppuccin.text      -- Brighter text on hover
    end

    local edge_foreground = background
    local title = tab_title(tab)
    -- ensure that the titles fit in the available space,
    -- and that we have room for the edges.
    title = wezterm.truncate_right(title, max_width - 2)

    return {
      { Background = { Color = background } },
      { Foreground = { Color = foreground } },
      { Text = " " .. title .. " " },
      { Background = { Color = background } },
      { Foreground = { Color = "#45475a" } },
      { Text = TAB_SEPARATOR },
    }
  end
)

config.keys = {
	{
		key = ']',
		mods = 'CMD',
		action = wezterm.action.SplitPane {
			direction = 'Right',
			size = { Percent = 50 },
		},
	},
	{
		key = '[',
		mods = 'CMD',
		action = wezterm.action.SplitPane {
			direction = 'Left',
			size = { Percent = 50 },
		},
	},
	{
		key = '-',
		mods = 'CMD',
		action = wezterm.action.SplitPane {
			direction = 'Up',
			size = { Percent = 50 },
		},
	},
	{
		key = '=',
		mods = 'CMD',
		action = wezterm.action.SplitPane {
			direction = 'Down',
			size = { Percent = 50 },
		},
	},
}

-- and finally, return the configuration to wezterm
return config
