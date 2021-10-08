local M = {}
function M.init()
  local tabline = require('tabline')
  require('lualine').setup {
    options = {
      theme = 'onedark'
    },
    sections = {
      lualine_a = {'mode'},
      lualine_b = {'g:coc_git_status'},
      lualine_c = {'filename'},
      lualine_x = {{ 'diagnostics', sources = {'coc'} }, 'encoding', 'fileformat', 'filetype'},
      lualine_y = {'progress'},
      lualine_z = {'location'}
    },
    tabline = {
      lualine_a = {},
      lualine_b = {},
      lualine_c = { tabline.tabline_buffers },
      lualine_x = { tabline.tabline_tabs },
      lualine_y = {},
      lualine_z = {},
    }
  }
end
return M
