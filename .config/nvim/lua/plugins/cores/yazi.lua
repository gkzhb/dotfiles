-- 文件管理器
local M = {
  'mikavilpas/yazi.nvim',
  config = function()
    vim.g.loaded_netrwPlugin = 1
  end,
}
function M.openYazi()
  local path = vim.fn.expand("%:p")
  if path ~= "" and path ~= nil and string.find(path, "://") and not string.find(path, "^file://") then
    -- for non-file buffers, show cwd
    require("yazi").yazi(nil, vim.fn.getcwd())

    return
  end

  require('yazi').yazi()
end

M.keys = {
  { '<leader>d', M.openYazi,          desc = 'open yazi' },
  { '<leader>D', '<cmd>Yazi cwd<CR>', desc = 'open yazi' },
}
return M
