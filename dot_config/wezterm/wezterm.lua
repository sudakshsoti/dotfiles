-- ~/.config/wezterm/wezterm.lua
-- Personal WezTerm config. Mirrors the Ghostty setup (Kohra theme, Berkeley
-- Mono, 12px padding, bar cursor) and adds a mac-native, leader-driven keymap.
--
-- Colour source of truth: ~/dev/kohra (themes/kohra-ghostty). The Kohra scheme
-- is embedded inline below so this file is self-contained; if the Kohra palette
-- changes, mirror the hexes here too.

local wezterm = require 'wezterm'
local act = wezterm.action
local config = wezterm.config_builder()

-- ─────────────────────────────────────────────────────────────────────────────
-- Theme — Kohra (cool fog-grey monochrome)
-- ─────────────────────────────────────────────────────────────────────────────
local kohra = {
  foreground    = '#babec1',
  background    = '#181b1d',
  cursor_bg     = '#78accf',
  cursor_fg     = '#181b1d',
  cursor_border = '#78accf',
  selection_bg  = '#0a3149',
  selection_fg  = '#babec1',

  ansi = {
    '#2b2e31', -- black
    '#b46768', -- red
    '#768a42', -- green
    '#a57635', -- yellow
    '#3e88b5', -- blue
    '#a86893', -- magenta
    '#1c9388', -- cyan
    '#828689', -- white
  },
  brights = {
    '#4a4d50', -- bright black
    '#e19796', -- bright red
    '#a4b776', -- bright green
    '#d2a56d', -- bright yellow
    '#76b6e1', -- bright blue
    '#d598c0', -- bright magenta
    '#65c1b5', -- bright cyan
    '#d3d8da', -- bright white
  },
}

config.color_schemes = {
  ['Kohra'] = {
    foreground       = kohra.foreground,
    background       = kohra.background,
    cursor_bg        = kohra.cursor_bg,
    cursor_fg        = kohra.cursor_fg,
    cursor_border    = kohra.cursor_border,
    selection_bg     = kohra.selection_bg,
    selection_fg     = kohra.selection_fg,
    scrollbar_thumb  = '#2b2e31',
    split            = '#2b2e31',
    ansi             = kohra.ansi,
    brights          = kohra.brights,
    -- Make the tab strip blend into the terminal surface (monochrome look).
    tab_bar = {
      background = kohra.background,
      active_tab        = { bg_color = kohra.background, fg_color = '#d3d8da', intensity = 'Bold' },
      inactive_tab      = { bg_color = kohra.background, fg_color = '#6a6e71' },
      inactive_tab_hover= { bg_color = '#202325', fg_color = '#babec1', italic = false },
      new_tab           = { bg_color = kohra.background, fg_color = '#6a6e71' },
      new_tab_hover     = { bg_color = '#202325', fg_color = '#babec1' },
    },
  },
}
config.color_scheme = 'Kohra'

-- ─────────────────────────────────────────────────────────────────────────────
-- Font — Berkeley Mono Nerd Font (matches Ghostty's BerkeleyMonoNFM)
-- ─────────────────────────────────────────────────────────────────────────────
config.font = wezterm.font_with_fallback {
  'BerkeleyMonoNFM',
  'Symbols Nerd Font Mono',
  'Apple Color Emoji',
}
config.font_size = 13.0
config.line_height = 1.12 -- ≈ Ghostty's adjust-cell-height = 12%
config.harfbuzz_features = { 'calt=1', 'liga=1', 'clig=1' } -- ligatures on
config.font_rasterizer = 'FreeType'
config.freetype_load_target = 'Light'
config.freetype_render_target = 'HorizontalLcd' -- crisper, slightly heavier stems
config.warn_about_missing_glyphs = false

-- ─────────────────────────────────────────────────────────────────────────────
-- Window & appearance
-- ─────────────────────────────────────────────────────────────────────────────
config.window_decorations = 'INTEGRATED_BUTTONS|RESIZE' -- keep traffic-light buttons, drop title bar
config.integrated_title_button_style = 'MacOsNative'
config.window_padding = { left = 12, right = 12, top = 12, bottom = 8 }
config.window_background_opacity = 1.0
-- For a frosted look instead, set opacity to ~0.92 and uncomment the next line:
-- config.macos_window_background_blur = 30
config.adjust_window_size_when_changing_font_size = false
config.window_close_confirmation = 'NeverPrompt'
config.front_end = 'WebGpu' -- best rendering on Apple Silicon
config.max_fps = 120
config.animation_fps = 60
config.scrollback_lines = 20000
config.audible_bell = 'Disabled'

-- Cursor — bar, like Ghostty's cursor-style = bar
config.default_cursor_style = 'SteadyBar'
config.cursor_thickness = '0.12cell'

-- ─────────────────────────────────────────────────────────────────────────────
-- Tab bar — minimal, blends in, hides when there's only one tab
-- ─────────────────────────────────────────────────────────────────────────────
config.enable_tab_bar = true
config.use_fancy_tab_bar = true
config.hide_tab_bar_if_only_one_tab = true
config.show_new_tab_button_in_tab_bar = false
config.show_tab_index_in_tab_bar = true
config.tab_max_width = 28
config.window_frame = {
  font = wezterm.font { family = 'BerkeleyMonoNFM', weight = 'Regular' },
  font_size = 12.0,
  active_titlebar_bg = kohra.background,
  inactive_titlebar_bg = kohra.background,
}

-- Clean tab titles: "1 · folder"  (process name when no explicit title)
local function basename(s)
  return string.gsub(s or '', '(.*[/\\])(.*)', '%2')
end

wezterm.on('format-tab-title', function(tab, _, _, _, _, max_width)
  local pane = tab.active_pane
  local title = tab.tab_title
  if not title or #title == 0 then
    title = basename(pane.foreground_process_name)
    if title == '' then
      title = basename(pane.current_working_dir and pane.current_working_dir.file_path or 'shell')
    end
  end
  local label = string.format(' %d · %s ', tab.tab_index + 1, title)
  if #label > max_width then
    label = wezterm.truncate_right(label, max_width - 1) .. '… '
  end
  return label
end)

-- Status bar:
--   left  → a spacer that pushes the tabs clear of the macOS traffic lights.
--   right → active key-table mode (e.g. when resizing panes).
-- The left-status area renders outside the tabs, so the gap is true empty
-- space rather than a wider first tab. Tune the spacer width below.
local LEFT_PAD = '    ' -- 4 spaces
wezterm.on('update-status', function(window, _)
  window:set_left_status(wezterm.format { { Text = LEFT_PAD } })
  local name = window:active_key_table()
  window:set_right_status(name and ('  ' .. name:upper() .. '  ') or '')
end)

-- ─────────────────────────────────────────────────────────────────────────────
-- Keys — leader is CTRL+a (tmux-muscle-memory); CMD bindings stay mac-native
-- ─────────────────────────────────────────────────────────────────────────────
config.leader = { key = 'a', mods = 'CTRL', timeout_milliseconds = 1000 }

config.keys = {
  -- Panes (mac-native CMD splits + leader splits)
  { key = 'd', mods = 'CMD',       action = act.SplitHorizontal { domain = 'CurrentPaneDomain' } },
  { key = 'd', mods = 'CMD|SHIFT', action = act.SplitVertical   { domain = 'CurrentPaneDomain' } },
  { key = '\\',mods = 'LEADER',    action = act.SplitHorizontal { domain = 'CurrentPaneDomain' } },
  { key = '-', mods = 'LEADER',    action = act.SplitVertical   { domain = 'CurrentPaneDomain' } },
  { key = 'w', mods = 'CMD',       action = act.CloseCurrentPane { confirm = true } },
  { key = 'z', mods = 'LEADER',    action = act.TogglePaneZoomState },

  -- Pane navigation (CTRL+h/j/k/l — vim-style; also works alongside nvim splits)
  { key = 'h', mods = 'CTRL', action = act.ActivatePaneDirection 'Left' },
  { key = 'j', mods = 'CTRL', action = act.ActivatePaneDirection 'Down' },
  { key = 'k', mods = 'CTRL', action = act.ActivatePaneDirection 'Up' },
  { key = 'l', mods = 'CTRL', action = act.ActivatePaneDirection 'Right' },

  -- Enter resize mode: LEADER r, then h/j/k/l (or arrows), Esc to exit
  { key = 'r', mods = 'LEADER', action = act.ActivateKeyTable { name = 'resize_pane', one_shot = false } },

  -- Tabs
  { key = 't', mods = 'CMD',       action = act.SpawnTab 'CurrentPaneDomain' },
  { key = '[', mods = 'CMD|SHIFT', action = act.ActivateTabRelative(-1) },
  { key = ']', mods = 'CMD|SHIFT', action = act.ActivateTabRelative(1) },
  { key = 'e', mods = 'LEADER',    action = act.PromptInputLine {
      description = 'Rename tab:',
      action = wezterm.action_callback(function(window, _, line)
        if line then window:active_tab():set_title(line) end
      end),
  } },

  -- Workspaces / sessions
  { key = 'p', mods = 'CMD|SHIFT', action = act.ShowLauncherArgs { flags = 'FUZZY|WORKSPACES|TABS' } },

  -- Search, copy mode, quick select
  { key = 'f', mods = 'CMD',       action = act.Search { CaseInSensitiveString = '' } },
  { key = 'x', mods = 'LEADER',    action = act.ActivateCopyMode },
  { key = ' ', mods = 'CMD|SHIFT', action = act.QuickSelect },
  { key = 'u', mods = 'LEADER',    action = act.CharSelect { copy_on_select = true } }, -- emoji/unicode picker

  -- Font size + misc
  { key = '0', mods = 'CMD', action = act.ResetFontSize },
  { key = '=', mods = 'CMD', action = act.IncreaseFontSize },
  { key = '-', mods = 'CMD', action = act.DecreaseFontSize },
  { key = 'k', mods = 'CMD', action = act.ClearScrollback 'ScrollbackAndViewport' },
  { key = 'Enter', mods = 'CMD', action = act.ToggleFullScreen },
}

-- CMD+1..9 → jump to tab
for i = 1, 9 do
  table.insert(config.keys, { key = tostring(i), mods = 'CMD', action = act.ActivateTab(i - 1) })
end

config.key_tables = {
  resize_pane = {
    { key = 'h', action = act.AdjustPaneSize { 'Left', 2 } },
    { key = 'j', action = act.AdjustPaneSize { 'Down', 2 } },
    { key = 'k', action = act.AdjustPaneSize { 'Up', 2 } },
    { key = 'l', action = act.AdjustPaneSize { 'Right', 2 } },
    { key = 'LeftArrow',  action = act.AdjustPaneSize { 'Left', 2 } },
    { key = 'DownArrow',  action = act.AdjustPaneSize { 'Down', 2 } },
    { key = 'UpArrow',    action = act.AdjustPaneSize { 'Up', 2 } },
    { key = 'RightArrow', action = act.AdjustPaneSize { 'Right', 2 } },
    { key = 'Escape', action = 'PopKeyTable' },
    { key = 'Enter',  action = 'PopKeyTable' },
  },
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Mouse & hyperlinks
-- ─────────────────────────────────────────────────────────────────────────────
config.hyperlink_rules = wezterm.default_hyperlink_rules()
-- CMD+click opens links; also linkify bare file paths and localhost URLs.
table.insert(config.hyperlink_rules, {
  regex = [[\b(localhost:\d+\S*)\b]],
  format = 'http://$1',
})

return config
