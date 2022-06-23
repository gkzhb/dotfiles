local windline = require('windline')
local floatline = require('wlfloatline')
local helper = require('windline.helpers')
local sep = helper.separators
local b_components = require('windline.components.basic')
local state = _G.WindLine.state
local vim_components = require('windline.components.vim')
local HSL = require('wlanimation.utils')
local wUtils = require('windline.utils')

local lsp_comps = require('windline.components.lsp')
local git_comps = require('windline.components.git')

local utils = require('wline.utils')
local seps = {
  left_circle = '', -- nf-ple-left_half_circle_thick
  left_circle_thin = '', -- nf-ple-left_half_circle_thin
  right_circle = '', -- nf-ple-right_half_circle_thick
  right_circle_thin = '', -- nf-ple-right_half_circle_thin
}
seps.left = seps.left_circle
seps.right = seps.right_circle

local hl_list = {
  Black = { 'white', 'black' },
  White = { 'black', 'white' },
  Normal = { 'NormalFg', 'NormalBg' },
  Inactive = { 'InactiveFg', 'InactiveBg' },
  Active = { 'ActiveFg', 'ActiveBg' },
}
local basic = {}

local airline_colors = {}

airline_colors.a = {
  NormalSep = { 'magenta_a', 'magenta_b' },
  InsertSep = { 'green_a', 'green_b' },
  VisualSep = { 'yellow_a', 'yellow_b' },
  ReplaceSep = { 'blue_a', 'blue_b' },
  CommandSep = { 'red_a', 'red_b' },
  Normal = { 'black', 'magenta_a' },
  Insert = { 'black', 'green_a' },
  Visual = { 'black', 'yellow_a' },
  Replace = { 'black', 'blue_a' },
  Command = { 'black', 'red_a' },
}

airline_colors.b = {
  NormalSep = { 'magenta_b', 'magenta_c' },
  InsertSep = { 'green_b', 'green_c' },
  VisualSep = { 'yellow_b', 'yellow_c' },
  ReplaceSep = { 'blue_b', 'blue_c' },
  CommandSep = { 'red_b', 'red_c' },
  Normal = { 'white', 'magenta_b' },
  Insert = { 'white', 'green_b' },
  Visual = { 'white', 'yellow_b' },
  Replace = { 'white', 'blue_b' },
  Command = { 'white', 'red_b' },
}

airline_colors.c = {
  NormalSep = { 'magenta_c', 'NormalBg' },
  InsertSep = { 'green_c', 'NormalBg' },
  VisualSep = { 'yellow_c', 'NormalBg' },
  ReplaceSep = { 'blue_c', 'NormalBg' },
  CommandSep = { 'red_c', 'NormalBg' },
  Normal = { 'white', 'magenta_c' },
  Insert = { 'white', 'green_c' },
  Visual = { 'white', 'yellow_c' },
  Replace = { 'white', 'blue_c' },
  Command = { 'white', 'red_c' },
}

basic.divider = { b_components.divider, hl_list.Normal }

local width_breakpoint = 100

local paste_mode = function()
  if vim.o.paste then
    return '  ' -- nf-mdi-content_paste
  end
end

basic.section_a = {
  hl_colors = airline_colors.a,
  text = function(_, _, width)
    if width > width_breakpoint then
      return {
        { ' ' .. state.mode[1], state.mode[2] },
        { paste_mode, state.mode[2] },
        { seps.right, state.mode[2] .. 'Sep' },
      }
    end
    return {
      { ' ' .. state.mode[1]:sub(1, 1) .. ' ', state.mode[2] },
      { paste_mode, state.mode[2] },
      { seps.right, state.mode[2] .. 'Sep' },
    }
  end,
}

local get_git_branch = git_comps.git_branch()
local file_modified = function(bufnr)
  -- computed based on bufnr
  local modified
  local modifiable
  if bufnr ~= nil then
    modified = vim.api.nvim_buf_get_option(bufnr, 'modified')
    modifiable = vim.api.nvim_buf_get_option(bufnr, 'modifiable')
  else
    modified = vim.bo.modified
    modifiable = vim.bo.modifiable
  end
  if modified then
    return ' ' -- nf-oct-pencil
  end
  if modifiable == false then
    return ' ' -- nf-mdi-pencil_off
  end
end

basic.section_b = {
  hl_colors = airline_colors.b,
  text = function(_, _, width)
    local branch_name = vim.g.coc_git_status or '' -- get_git_branch()
    if width > width_breakpoint and #branch_name > 1 then
      return {
        { ' ' .. branch_name, state.mode[2] },
        { ' ', '' },
        { seps.right, state.mode[2] .. 'Sep' },
      }
    end
    return { { seps.right, state.mode[2] .. 'Sep' } }
  end,
}

basic.section_c = {
  hl_colors = airline_colors.c,
  text = function(bufnr)
    return {
      { ' ', state.mode[2] },
      { b_components.cache_file_name('[No Name]', 'unique') },
      { file_modified(bufnr), '' },
      { seps.right, state.mode[2] .. 'Sep' },
    }
  end,
}

basic.section_x = {
  hl_colors = airline_colors.c,
  text = function(_, _, width)
    if width > width_breakpoint then
      return {
        { seps.left, state.mode[2] .. 'Sep' },
        { ' ', state.mode[2] },
        { b_components.file_encoding() },
        { ' ' },
        { b_components.file_format({ icon = true }) },
        { ' ' },
      }
    end
    return {
      { seps.left, state.mode[2] .. 'Sep' },
    }
  end,
}

basic.section_y = {
  hl_colors = airline_colors.b,
  text = function(_, _, width)
    if width > width_breakpoint then
      return {
        { seps.left, state.mode[2] .. 'Sep' },
        { ' ', state.mode[2] },
        { b_components.cache_file_type({ icon = true }), state.mode[2] },
        { ' ' },
      }
    end
    return { { seps.left, state.mode[2] .. 'Sep' } }
  end,
}

basic.section_z = {
  hl_colors = airline_colors.a,
  text = function(_, _, width)
    if width > width_breakpoint then
      return {
        { seps.left, state.mode[2] .. 'Sep' },
        { '', state.mode[2] },
        { b_components.progress_lua },
        { ' ' },
        { b_components.line_col_lua },
      }
    end
    return {
      { seps.left, state.mode[2] .. 'Sep' },
      { ' ', state.mode[2] },
      { b_components.line_col_lua, state.mode[2] },
    }
  end,
}

basic.lsp_diagnos = {
  name = 'diagnostic',
  hl_colors = {
    red = { 'red', 'NormalBg' },
    yellow = { 'yellow', 'NormalBg' },
    blue = { 'blue', 'NormalBg' },
  },
  text = function(bufnr)
    local diag = wUtils.buf_get_var(bufnr, 'coc_diagnostic_info')
    if diag then
      return {
        { ' ', 'red' },
        { utils.format({ format = ' %s ', value = diag.error }), 'red' },
        { utils.format({ format = ' %s ', value = diag.warning }), 'yellow' },
        { utils.format({ format = ' %s', value = diag.information }), 'blue' },
      }
    end
    return { ' ', 'red' }
  end,
}

basic.git = {
  name = 'git',
  width = width_breakpoint,
  hl_colors = {
    green = { 'green', 'NormalBg' },
    red = { 'red', 'NormalBg' },
    blue = { 'blue', 'NormalBg' },
  },
  text = function(bufnr)
    local buf_git_status = wUtils.buf_get_var(bufnr, 'coc_git_status')
    if buf_git_status then
      return {
        { ' ', '' },
        { utils.format({ format = ' %s', value = string.match(buf_git_status, '+(%d+)') }), 'green' },
        { utils.format({ format = '  %s', value = string.match(buf_git_status, '-(%d+)') }), 'red' },
        { utils.format({ format = ' 柳%s', value = string.match(buf_git_status, '~(%d+)') }), 'blue' },
        { ' ', '' },
      }
    end
    return ''
  end,
}

local quickfix = {
  filetypes = { 'qf', 'Trouble' },
  active = {
    { '🚦 Quickfix ', { 'white', 'black' } },
    { helper.separators.slant_right, { 'black', 'black_light' } },
    {
      function()
        return vim.fn.getqflist({ title = 0 }).title
      end,
      { 'cyan', 'black_light' },
    },
    { ' Total : %L ', { 'cyan', 'black_light' } },
    { helper.separators.slant_right, { 'black_light', 'InactiveBg' } },
    { ' ', { 'InactiveFg', 'InactiveBg' } },
    basic.divider,
    { helper.separators.slant_right, { 'InactiveBg', 'black' } },
    { '🧛 ', { 'white', 'black' } },
  },
  always_active = true,
  show_last_status = true,
}

local explorer = {
  filetypes = { 'fern', 'NvimTree', 'lir', 'coc-explorer' },
  active = {
    { '  ', { 'white', 'magenta_b' } },
    { helper.separators.slant_right, { 'magenta_b', 'NormalBg' } },
    { b_components.divider, '' },
    { b_components.file_name(''), { 'NormalFg', 'NormalBg' } },
  },
  always_active = true,
  show_last_status = true,
  floatline_show_float = true,
  floatline_show_both = true,
}

local default = {
  filetypes = { 'default' },
  active = {
    basic.section_a,
    basic.section_b,
    basic.section_c,
    basic.lsp_diagnos,
    { utils.searchCount(), { 'cyan', 'NormalBg' } },
    basic.divider,
    basic.git,
    basic.section_x,
    basic.section_y,
    basic.section_z,
  },
  inactive = {
    basic.section_c,
    -- { b_components.full_file_name, hl_list.Inactive },
    basic.divider,
    -- { b_components.divider, hl_list.Inactive },
    {
      hl_colors = airline_colors.c,
      text = basic.section_z.text,
    },
    -- { b_components.line_col, hl_list.Inactive },
    -- { b_components.progress, hl_list.Inactive },
  },
  floatline_show_float = false,
  -- floatline_show_both = true,
}

windline.setup({
  colors_name = function(colors)
    local mod = function(c, value)
      if vim.o.background == 'light' then
        return HSL.rgb_to_hsl(c):tint(value):to_rgb()
      end
      return HSL.rgb_to_hsl(c):shade(value):to_rgb()
    end

    colors.magenta_a = colors.magenta
    colors.magenta_b = mod(colors.magenta, 0.5)
    colors.magenta_c = mod(colors.magenta, 0.7)

    colors.yellow_a = colors.yellow
    colors.yellow_b = mod(colors.yellow, 0.5)
    colors.yellow_c = mod(colors.yellow, 0.7)

    colors.blue_a = colors.blue
    colors.blue_b = mod(colors.blue, 0.5)
    colors.blue_c = mod(colors.blue, 0.7)

    colors.green_a = colors.green
    colors.green_b = mod(colors.green, 0.5)
    colors.green_c = mod(colors.green, 0.7)

    colors.red_a = colors.red
    colors.red_b = mod(colors.red, 0.5)
    colors.red_c = mod(colors.red, 0.7)

    return colors
  end,
  statuslines = {
    default,
    quickfix,
    explorer,
  },
})
