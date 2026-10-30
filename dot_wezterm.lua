-- Pull in the wezterm API
local wezterm = require("wezterm")

-- This will hold the configuration.
local config = wezterm.config_builder()

-- Default shell
config.default_prog = { "/usr/bin/zsh", "-l" }

-- Current colorscheme
config.color_scheme = "Rosé Pine (Gogh)"

-- Font configuration with Nerd Font fallback
config.font = wezterm.font_with_fallback({
  "JetBrains Mono",
  "IoskeleyMono Nerd Font Mono",
  "Symbols Nerd Font Mono",
})
config.font_size = 12

-- UI Styling
config.window_background_opacity = 1.0
config.text_background_opacity = 1.0
config.window_padding = { left = 8, right = 8, top = 8, bottom = 8 }
config.window_decorations = "NONE"
config.adjust_window_size_when_changing_font_size = false

-- Blur settings (effective on compositors supporting Wayland blur such as KDE KWin or SwayFX)
config.wayland_window_background_blur = true

-- Rosé Pine Palette
local rose_pine = {
  base = "#191724",
  surface = "#1f1d2e",
  overlay = "#26233a",
  muted = "#6e6a86",
  subtle = "#908caa",
  text = "#e0def4",
  love = "#eb6f92",
  gold = "#f6c177",
  rose = "#ebbcba",
  pine = "#31748f",
  foam = "#9ccfd8",
  iris = "#c4a7e7",
  highlight_med = "#403d52",
}

-- Tab Bar Settings
config.enable_tab_bar = true
config.use_fancy_tab_bar = false
config.hide_tab_bar_if_only_one_tab = false
config.tab_bar_at_bottom = true

-- Tab Bar Colors
config.colors = {
  tab_bar = {
    background = rose_pine.base,
    active_tab = {
      bg_color = rose_pine.rose,
      fg_color = rose_pine.base,
      intensity = "Bold",
    },
    inactive_tab = {
      bg_color = rose_pine.overlay,
      fg_color = rose_pine.subtle,
    },
    inactive_tab_hover = {
      bg_color = rose_pine.highlight_med,
      fg_color = rose_pine.text,
    },
    new_tab = {
      bg_color = rose_pine.base,
      fg_color = rose_pine.subtle,
    },
    new_tab_hover = {
      bg_color = rose_pine.overlay,
      fg_color = rose_pine.rose,
    },
  },
}

-- Function to extract basename from a path
local function basename(s)
  return string.gsub(s, "(.*[/\\])(.*)", "%2")
end

-- Helper to get the real process name
local function get_process_name(pane)
  local process_info = pane:get_foreground_process_info()
  if not process_info then
    return pane:get_title()
  end

  local name = basename(process_info.executable)

  -- Handle sudo
  if name == "sudo" then
    for i, arg in ipairs(process_info.argv) do
      if i > 1 and not arg:find("^-") then
        name = basename(arg)
        break
      end
    end
  end

  -- Handle node/npx
  if name == "node" then
    for i, arg in ipairs(process_info.argv) do
      if i > 1 and arg:find("%.js$") then
        name = basename(arg):gsub("%.js$", "")
        break
      elseif i > 1 and not arg:find("^-") then
        name = basename(arg)
        break
      end
    end
  end

  -- Handle snap
  if name == "snap" and #process_info.argv > 1 then
    name = basename(process_info.argv[2])
  end

  -- Handle specialized snap paths (e.g., /snap/bin/nvim)
  if process_info.executable:find("^/snap/") then
    name = basename(process_info.executable)
  end

  return name
end

-- Mapping of process names to icons
local function get_process_icon(process_name)
  local icons = {
    ["nvim"] = "",
    ["vim"] = "",
    ["zsh"] = "",
    ["bash"] = "",
    ["sh"] = "",
    ["node"] = "",
    ["python"] = "",
    ["python3"] = "",
    ["git"] = "󰊢",
    ["ssh"] = "󰣀",
    ["sudo"] = "󰒲",
    ["docker"] = "󰡨",
    ["docker-compose"] = "󰡨",
    ["cargo"] = "",
    ["go"] = "",
    ["npm"] = "",
    ["yarn"] = "",
    ["pnpm"] = "",
    ["gh"] = "",
    ["top"] = "",
    ["htop"] = "",
    ["btm"] = "",
    ["yazi"] = "󱗆",
  }
  return icons[process_name] or "󰆍"
end

-- Custom tab title: [icon] [index]: [command] with Rosé Pine Powerline arrows
wezterm.on("format-tab-title", function(tab, tabs, panes, config, hover, max_width)
  local background = rose_pine.overlay
  local foreground = rose_pine.subtle

  if tab.is_active then
    background = rose_pine.rose
    foreground = rose_pine.base
  elseif hover then
    background = rose_pine.highlight_med
    foreground = rose_pine.text
  end

  -- Determine background of the subsequent element for seamless powerline arrow
  local next_bg = rose_pine.base
  if tab.tab_index + 1 < #tabs then
    local next_tab = tabs[tab.tab_index + 2]
    if next_tab.is_active then
      next_bg = rose_pine.rose
    else
      next_bg = rose_pine.overlay
    end
  end

  local process_name = get_process_name(tab.active_pane)
  local icon = get_process_icon(process_name)
  local title = (process_name == "" or process_name == "zsh") and tab.active_pane.title or process_name

  -- Handle the special case where title might be the same as the shell
  if title == "zsh" then
    title = "term"
  end

  return {
    { Background = { Color = background } },
    { Foreground = { Color = foreground } },
    { Attribute = { Intensity = tab.is_active and "Bold" or "Normal" } },
    { Text = " " .. icon .. " " .. (tab.tab_index + 1) .. ": " .. title .. " " },
    { Background = { Color = next_bg } },
    { Foreground = { Color = background } },
    { Text = "" }, -- SOLID_RIGHT_ARROW
  }
end)

-- Dynamic Status (Right side of tab bar) in Rosé Pine palette
wezterm.on("update-right-status", function(window, pane)
  local date = wezterm.strftime("%H:%M  %d-%b")
  local workspace = window:active_workspace()

  window:set_right_status(wezterm.format({
    -- Workspace segment
    { Foreground = { Color = rose_pine.overlay } },
    { Background = { Color = rose_pine.base } },
    { Text = "" },
    { Background = { Color = rose_pine.overlay } },
    { Foreground = { Color = rose_pine.iris } },
    { Text = " 󱂬 " .. workspace .. " " },

    -- Date/Time segment
    { Foreground = { Color = rose_pine.rose } },
    { Background = { Color = rose_pine.overlay } },
    { Text = "" },
    { Background = { Color = rose_pine.rose } },
    { Foreground = { Color = rose_pine.base } },
    { Attribute = { Intensity = "Bold" } },
    { Text = " 󱑒 " .. date .. " " },
  }))
end)

-- Performance & Wayland Optimizations
config.enable_wayland = true
config.front_end = "WebGpu"
config.webgpu_power_preference = "HighPerformance"
config.max_fps = 144
config.enable_kitty_graphics = true
config.alternate_buffer_wheel_scroll_speed = 3
config.scrollback_lines = 10000

-- Interaction Settings
config.window_close_confirmation = "NeverPrompt"
config.check_for_updates = false
config.selection_word_boundary = " \t\n{}[]()\"'`,;:│=&!%"

-- Keybindings
local hyper = "CTRL|ALT|SUPER"
config.leader = { key = "F13", mods = "", timeout_milliseconds = 1000 }

config.keys = {
  -- Pane Management
  { key = "\\", mods = hyper, action = wezterm.action.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
  { key = "-",  mods = hyper, action = wezterm.action.SplitVertical({ domain = "CurrentPaneDomain" }) },
  { key = "h",  mods = hyper, action = wezterm.action.ActivatePaneDirection("Left") },
  { key = "j",  mods = hyper, action = wezterm.action.ActivatePaneDirection("Down") },
  { key = "k",  mods = hyper, action = wezterm.action.ActivatePaneDirection("Up") },
  { key = "l",  mods = hyper, action = wezterm.action.ActivatePaneDirection("Right") },
  { key = "H",  mods = hyper, action = wezterm.action.AdjustPaneSize({ "Left", 5 }) },
  { key = "J",  mods = hyper, action = wezterm.action.AdjustPaneSize({ "Down", 5 }) },
  { key = "K",  mods = hyper, action = wezterm.action.AdjustPaneSize({ "Up", 5 }) },
  { key = "L",  mods = hyper, action = wezterm.action.AdjustPaneSize({ "Right", 5 }) },
  { key = "w",  mods = hyper, action = wezterm.action.CloseCurrentPane({ confirm = true }) },
  { key = "z",  mods = hyper, action = wezterm.action.TogglePaneZoomState },
  { key = "r",  mods = hyper, action = wezterm.action.RotatePanes("Clockwise") },
  { key = "R",  mods = hyper, action = wezterm.action.RotatePanes("CounterClockwise") },

  -- Tab & Window Management
  { key = "t",  mods = hyper, action = wezterm.action.SpawnTab("CurrentPaneDomain") },
  { key = "n",  mods = hyper, action = wezterm.action.SpawnWindow },
  { key = "1",  mods = hyper, action = wezterm.action.ActivateTab(0) },
  { key = "2",  mods = hyper, action = wezterm.action.ActivateTab(1) },
  { key = "3",  mods = hyper, action = wezterm.action.ActivateTab(2) },
  { key = "4",  mods = hyper, action = wezterm.action.ActivateTab(3) },
  { key = "5",  mods = hyper, action = wezterm.action.ActivateTab(4) },

  -- Font Scaling
  { key = "=",  mods = hyper, action = wezterm.action.IncreaseFontSize },
  { key = "_",  mods = hyper, action = wezterm.action.DecreaseFontSize },
  { key = "0",  mods = hyper, action = wezterm.action.ResetFontSize },

  -- Search & Clipboard
  { key = "p",  mods = hyper, action = wezterm.action.ActivateCommandPalette },
  { key = "f",  mods = hyper, action = wezterm.action.Search({ CaseSensitiveString = "" }) },
  { key = "c",  mods = hyper, action = wezterm.action.CopyTo("Clipboard") },
  { key = "v",  mods = hyper, action = wezterm.action.PasteFrom("Clipboard") },

  -- Utilities
  {
    key = "y",
    mods = hyper,
    action = wezterm.action_callback(function(window, pane)
      local cwd = pane:get_current_working_dir()
      local cwd_path = cwd and cwd.file_path or os.getenv("HOME")
      window:perform_action(
        wezterm.action.SpawnCommandInNewTab({
          args = { "yazi", cwd_path },
          domain = "CurrentPaneDomain",
        }),
        pane
      )
    end),
  },
  {
    key = "x",
    mods = hyper,
    action = wezterm.action.Multiple({
      wezterm.action.ClearScrollback("ScrollbackAndViewport"),
      wezterm.action.SendKey({ key = "L", mods = "CTRL" }),
    }),
  },
}

-- Inactive pane dimming
config.inactive_pane_hsb = {
  saturation = 0.8,
  brightness = 0.6,
}

return config
