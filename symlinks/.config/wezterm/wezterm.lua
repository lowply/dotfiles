local wezterm = require 'wezterm'
local config = wezterm.config_builder()

config.font = wezterm.font('SF Mono')
config.font_size = 14
config.line_height = 1.2

config.colors = {
  foreground = 'white',
  cursor_bg = '#ccc',
  selection_bg = '#555',
  split = '#555',
  compose_cursor = 'orange',
}

config.window_decorations = 'RESIZE'

config.window_frame = {
  font = wezterm.font('SF Mono', { weight = 'Bold' }),
}

wezterm.on('update-status', function(window)
  window:set_right_status(wezterm.format({
    {
      Text = ' '
      .. wezterm.hostname()
      .. ' | '
      .. wezterm.strftime('%a %Y-%m-%d %H:%M:%S')
      .. ' '
    },
  }))
end)

local function move_pane(key, direction)
  return {
    key = key,
    mods = 'SHIFT',
    action = wezterm.action.ActivatePaneDirection(direction),
  }
end

local function resize_pane(key, direction)
  return {
    key = key,
    action = wezterm.action.AdjustPaneSize { direction, 3 }
  }
end

config.keys = {
  {
    key = ',',
    mods = 'CMD',
    action = wezterm.action.SpawnCommandInNewTab {
      cwd = wezterm.home_dir,
      args = { 'vim', wezterm.config_file },
    },
  },
  {
    key = 'Enter',
    mods = 'CMD|SHIFT',
    action = wezterm.action.SplitVertical { domain = 'CurrentPaneDomain' },
  },
  {
    key = 'Enter',
    mods = 'CMD',
    action = wezterm.action.SplitHorizontal { domain = 'CurrentPaneDomain' },
  },
  {
    key = 'p',
    mods = 'CTRL',
    action = wezterm.action{
      ActivatePaneDirection = 'Prev'
    }
  },
  {
    key = 'n',
    mods = 'CTRL',
    action = wezterm.action{
      ActivatePaneDirection = 'Next'
    }
  },
  {
    key = 'r',
    mods = 'CMD|SHIFT',
    action = wezterm.action.ActivateKeyTable {
      name = 'resize_panes',
      one_shot = false,
      timeout_milliseconds = 1000,
    }
  },
}

config.key_tables = {
  resize_panes = {
    resize_pane('j', 'Down'),
    resize_pane('k', 'Up'),
    resize_pane('h', 'Left'),
    resize_pane('l', 'Right'),
  },
}

config.set_environment_variables = {
  PATH = '/opt/homebrew/bin:' .. os.getenv('PATH')
}

config.ssh_domains = {
  {
    name = 'u',
    remote_address = 'u.svifa.net:1417',
    username = 'sho',
  },
}

config.inactive_pane_hsb = {
  hue = 1.0,
  saturation = 1.0,
  brightness = 0.6,
}

return config

