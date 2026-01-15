-- 文件管理器
local M = {
  'mikavilpas/yazi.nvim',
  config = function()
    vim.g.loaded_netrwPlugin = 1
  end,
}

M.keys = {
  { '<leader>d', '<cmd>Yazi<CR>', desc = 'open yazi' },
  { '<leader>D', '<cmd>Yazi cwd<CR>', desc = 'open yazi' },
}
return M
