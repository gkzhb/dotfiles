local M = {}
function M.init()
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
    tabline = {}
  }
end
return M
