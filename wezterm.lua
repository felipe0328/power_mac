local wezterm = require 'wezterm'
local config = wezterm.config_builder()

-- Font
config.font = wezterm.font 'MesloLGS NF'
config.font_size = 14.0

-- Theme
config.color_scheme = 'Tokyo Night'

-- Window
config.window_padding = { left = 8, right = 8, top = 8, bottom = 8 }
config.window_background_opacity = 1.0
config.window_decorations = 'TITLE | RESIZE'
config.window_close_confirmation = 'NeverPrompt'

-- Cursor
config.default_cursor_style = 'SteadyBlock'
config.hide_mouse_cursor_when_typing = true

-- Tabs
config.hide_tab_bar_if_only_one_tab = true

-- Scrolling
config.scrollback_lines = 50000
config.enable_scroll_bar = false

-- Rendering — explicit WebGPU for AeroSpace compatibility
config.front_end = 'WebGpu'

-- macOS
config.native_macos_fullscreen_mode = true
-- Make Option behave as Alt (same as macos-option-as-alt = true)
config.send_composed_key_when_left_alt_is_pressed = false
config.send_composed_key_when_right_alt_is_pressed = false

return config
