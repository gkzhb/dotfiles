local wezterm = require 'wezterm'
local bar = wezterm.plugin.require("https://github.com/adriankarlen/bar.wezterm")

local config = {
  -- disable update check
  check_for_updates = false,
  -- 字体配置
  font = wezterm.font_with_fallback({
    "RobotoMono Nerd Font",
    "Noto Sans CJK SC",
  }),
  font_size = 14,

  -- 颜色方案 (从 Kitty 配置中提取)
  colors = {
    foreground = "#abb2bf",
    background = "#1e1e1e",
    cursor_bg = "#f2dcd3",
    cursor_fg = "#1e1e1e",
    selection_bg = "#3e4452",
    selection_fg = "#abb2bf",
    
    -- 16 色终端颜色
    ansi = {
      "#1e1e1e",  -- black
      "#e06c75",  -- red
      "#98c379",  -- green
      "#e5c07b",  -- yellow
      "#61afef",  -- blue
      "#c678dd",  -- magenta
      "#56b6c2",  -- cyan
      "#abb2bf",  -- white
    },
    brights = {
      "#5c6370",   -- bright black
      "#e05661",   -- bright red
      "#1da912",   -- bright green
      "#eea825",   -- bright yellow
      "#118dc3",   -- bright blue
      "#9a77cf",   -- bright magenta
      "#98d3cb",   -- bright cyan
      "#3e4452",   -- bright white
    },
  },

  -- 背景透明度
  -- window_background_opacity = 0.8,

  -- 光标配置
  -- default_cursor_style = "SteadyBlock",
  -- cursor_blink_rate = 0,  -- 禁用光标闪烁

  -- 滚动配置
  scrollback_lines = 2000,

  -- Tab 配置
  enable_tab_bar = true,
  tab_bar_at_bottom = false,
  
  -- 窗口配置
  window_padding = {
    left = 0,
    right = 0,
    top = 0,
    bottom = 0,
  },

  -- 禁用 ligatures
  harfbuzz_features = {"calt=0", "clig=0", "liga=0"},

  -- 键盘快捷键 (Kitty 风格的映射)
  keys = {
    -- 字体大小调整
    {key="=", mods="CTRL|SHIFT", action=wezterm.action.IncreaseFontSize},
    {key="-", mods="CTRL|SHIFT", action=wezterm.action.DecreaseFontSize},
    
    -- Tab 导航
    {key="t", mods="CTRL|SHIFT", action=wezterm.action.SpawnTab("DefaultDomain")},
    {key="w", mods="CTRL|SHIFT", action=wezterm.action.CloseCurrentTab{confirm=true}},
    {key="]", mods="CTRL|SHIFT", action=wezterm.action.ActivateTabRelative(1)},
    {key="[", mods="CTRL|SHIFT", action=wezterm.action.ActivateTabRelative(-1)},
    
    -- 窗口导航
    {key="Enter", mods="CTRL|SHIFT", action=wezterm.action.SpawnWindow},
    {key="d", mods="CTRL|SHIFT", action=wezterm.action.CloseCurrentPane{confirm=true}},
    
    -- 滚动
    {key="k", mods="CTRL|SHIFT", action=wezterm.action.ScrollByLine(-1)},
    {key="j", mods="CTRL|SHIFT", action=wezterm.action.ScrollByLine(1)},
    {key="h", mods="CTRL|SHIFT", action=wezterm.action.ShowLauncher},
    
    -- 复制粘贴
    {key="c", mods="CTRL|SHIFT", action=wezterm.action.CopyTo("Clipboard")},
    {key="v", mods="CTRL|SHIFT", action=wezterm.action.PasteFrom("Clipboard")},
    
    -- 全屏
    {key="f", mods="CTRL|SHIFT", action=wezterm.action.ToggleFullScreen},
    
    -- 重置字体大小
    {key="0", mods="CTRL|SHIFT", action=wezterm.action.ResetFontSize},
  },

  -- 鼠标配置
  mouse_bindings = {
    -- 右键粘贴
    {
      event={Down={streak=1, button="Right"}},
      mods="NONE",
      action=wezterm.action.PasteFrom("Clipboard"),
    },
    -- Ctrl+左键打开链接
    {
      event={Up={streak=1, button="Left"}},
      mods="CTRL",
      action=wezterm.action.OpenLinkAtMouseCursor,
    },
  },

  -- 性能优化
  max_fps = 60,
  front_end = "WebGpu",

  -- Shell 配置
  default_prog = {"/opt/homebrew/bin/fish", "-l"},

  -- 终端类型
  term = "wezterm",
}

bar.apply_to_config(config, {
  position = 'top',
})
return config
