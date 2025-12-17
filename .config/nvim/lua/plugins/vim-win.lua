local M = {}

function M.init()
  vim.g.win_ext_command_map = {
    w = 'w',
    x = 'Win#exit',
    c = 'wincmd c',
    C = 'close!',
    q = 'quit',
    Q = 'quit!',
    ['!'] = 'qall!',
    V = 'wincmd v',
    S = 'wincmd s',
    n = 'bnext',
    N = 'bnext!',
    p = 'bprevious',
    P = 'bprevious!',
    ['<C-N>'] = 'tabnext', -- not working now
    ['<C-P>'] = 'tabprevious', -- not working now
    ['='] = 'wincmd =',
    t = 'tabnew',
  }
end

function M.mappings()
  local wk = require('which-key')
  wk.register({
    w = { '<cmd>call win#Win()<CR>', 'win mode' },
  }, { mode = 'n', prefix = '<leader>' })
end

return {}
