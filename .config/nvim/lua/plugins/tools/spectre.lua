-- 搜索替换
local M = {
  'nvim-pack/nvim-spectre',
  dependencies = { 'nvim-lua/plenary.nvim' },
}

function M.config() end

M.keys = {
  { '<leader>S', '<cmd>lua require("spectre").toggle()<CR>', desc = 'Search', mode = 'n' },
}

return M
