-- 问题列表
local M = {
  'folke/trouble.nvim',
  dependencies = { 'kyazdani42/nvim-web-devicons' },
}

function M.config()
  require('trouble').setup({
    -- your configuration comes here
    -- or leave it empty to use the default settings
    -- refer to the configuration section below
  })
end

return M
