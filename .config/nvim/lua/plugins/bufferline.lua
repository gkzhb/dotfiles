local M = {}

function M.init()
  local colors = require('onedarkpro.helpers').get_colors('onedark')

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
        fg = colors.white,
        bg = colors.bg0,
        bold = true,
      },
      buffer_selected = {
        fg = colors.white,
        bg = colors.bg0,
        bold = true,
        italic = true,
      },
      numbers_selected = {
        fg = colors.white,
        bg = colors.bg0,
      },
      separator_selected = {
        fg = colors.white,
        bg = colors.bg0,
      },
      indicator_selected = {
        fg = colors.white,
        bg = colors.bg0,
      },
    },
  })
end

return M
