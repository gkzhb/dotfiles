local M = {}

function M.init()
  local c = require('vscode.colors').get_colors()
  local selected_bg = c.vscTabCurrent
  local selected_fg = c.vscFront

  require('bufferline').setup({
    options = {
      numbers = function(opts)
        return string.format('%s', opts.id)
      end,
      show_tab_indicators = true,
      always_show_bufferline = true,
      show_close_icon = false,
      show_buffer_close_icons = false,
      diagnostics = 'coc',
    },
    highlights = {
      tab_selected = {
        fg = selected_fg,
        bg = selected_bg,
        bold = true,
      },
      buffer_selected = {
        fg = selected_fg,
        bg = selected_bg,
        bold = true,
        italic = true,
      },
      numbers_selected = {
        fg = selected_fg,
        bg = selected_bg,
      },
      separator_selected = {
        fg = selected_fg,
        bg = selected_bg,
      },
      indicator_selected = {
        fg = selected_fg,
        bg = selected_bg,
      },
    },
  })
end

return M
