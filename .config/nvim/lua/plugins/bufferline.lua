local M = {}

function M.init()
  require('bufferline').setup({
    options = {
      show_tab_indicators = true,
      always_show_bufferline = true,
      show_close_icon = false,
      show_buffer_close_icons = false,
      diagnostics = 'coc',
    }
  })
end

return M
