local M = {}

function M.init()
  vim.g.win_ext_command_map = {
    q = 'q',
    w = 'w',
    x = 'Win#exit',
  }
end

function M.mappings()
  local wk = require('which-key')
  wk.register({
    w = { '<cmd>call win#Win()<CR>', 'win mode' },
  }, { mode = 'n', prefix = '<leader>' })
end

return M
