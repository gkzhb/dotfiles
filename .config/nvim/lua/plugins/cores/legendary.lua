local M = {
  'mrjones2014/legendary.nvim',
}
function M.config()
  require('legendary').setup({})
end
function M.mappings()
  local wk = require('which-key')
  wk.register({
    si = { '<cmd>Legendary<CR>', 'search keymaps, cmds, autocmds' },
  }, { prefix = '<leader>' })
end
return M
