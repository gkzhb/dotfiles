local M = {}

function M.init()
  require('neoclip').setup({})
  require('telescope').load_extension('neoclip')
end

return M
