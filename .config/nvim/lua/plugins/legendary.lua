local M = {}
function M.init()
  require('legendary').setup({})
end
function M.mappings()
  local wk = require('which-key')
  wk.register({
    i = { '<cmd>Legendary<CR>', 'search keymaps, cmds, autocmds' },
  }, { prefix = '<leader>' })
end
return M
