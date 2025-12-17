-- 搜索替换
local M = {
  'nvim-pack/nvim-spectre',
  dependencies = { 'nvim-lua/plenary.nvim' },
}

function M.config() end

function M.mappings()
  local wk = require('which-key')
  wk.register({
    S = { '<cmd>lua require("spectre").toggle()<CR>', 'Search' },
  }, { prefix = '<leader>', mode = 'n' })
end

return M
