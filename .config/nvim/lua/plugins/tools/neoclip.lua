-- 剪贴板管理
local M = {
  'AckslD/nvim-neoclip.lua',
  dependencies = { 'nvim-telescope/telescope.nvim', 'tami5/sqlite.lua' },
}

function M.config()
  require('neoclip').setup({})
  require('telescope').load_extension('neoclip')
end

return M
