local M = {}

function M.init()
  local colors = require('onedarkpro').get_colors('onedark')

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
          guifg = colors.white,
          guibg = colors.bg0,
          gui = 'bold',
      },
    }
  })
end

return M
