local M = {}
local utils = require('utils')
local map = utils.map

function _G.SetTab(size)
  vim.opt.tabstop = size
  vim.opt.softtabstop = size
  vim.opt.shiftwidth = size
end

function _G.SynGroup()
    local s = vim.fn.synID(vim.fn.line('.'), vim.fn.col('.'), 1)
    print(vim.fn.synIDattr(s, 'name') .. ' -> ' .. vim.fn.synIDattr(vim.fn.synIDtrans(s), 'name'))
end

function _G.SynStack()
  local res = vim.fn.synstack(vim.fn.line('.'), vim.fn.col('.'))
  for s = 1, #res do
    local i1 = res[s]
    local i2 = vim.fn.synIDtrans(i1)
    local n1 = vim.fn.synIDattr(i1, 'name')
    local n2 = vim.fn.synIDattr(i2, 'name')
    print(n1 .. '->' .. n2)
  end
  if #res == 0 then
    print('no hl group')
  end
end

-- switch current active buffer to buffer number c
function _G.SwitchBuffer(c)
  if c > 0 and vim.fn.bufnr(c) > -1 then
    return utils.esc(':<C-U>' .. c .. 'b<CR>')
  end
  return ''
end

function M.init()
  -- leader key
  vim.g.mapleader=' '
  vim.g.maplocalleader=' '
  vim.opt.ttimeout=true
  vim.opt.tm=500
end

function M.setMappings()
  local wk = require('which-key')

  wk.register({
    ['-'] = { '<Plug>(choosewin)', 'choose win', noremap = false, silent = true }, -- choosewin
    -- buffer actions
    ['<C-N>'] = { ':bnext<CR>', 'next buffer' },
    ['<C-P>'] = { ':bprev<CR>', 'previous buffer' },
    -- [n]gb switch to buffer [n]
    gb = { 'v:lua.SwitchBuffer(v:count)', 'switch to buffer [n]', expr = true }
  })
  
  -- quick actions
  wk.register({
    c = {
      name = 'config',
      i = { '<cmd>set list!<CR>', 'toggle showing space chars' },
      h = { '<cmd>noh<CR>', 'hide search highlight' },
      p = { '<cmd>set invpaste', 'toggle paste mode' },
      t4 = { '<cmd>call v:lua.SetTab(4)<CR>', 'set tab size 4' },
      t2 = { '<cmd>call v:lua.SetTab(2)<CR>', 'set tab size 2' },
    },
    d = { '<cmd>Lf<CR>', 'open lf' }, -- lf
    h = { -- highlight related
      name = 'show highlight',
      s = { '<cmd>lua SynGroup()<CR>', 'get SynGroup' },
      ss = { '<cmd>lua SynStack()<CR>', 'get SynStack' },
      t = { '<cmd>TSHighlightCapturesUnderCursor<CR>', 'get treesitter highlight' },
      r = { '<cmd>write | edit | TSBufEnable highlight<CR>', 'refresh treesitter highlight' },
    },
    t = {
      name = 'tab actions',
      n = { '<cmd>tabnew<CR>', 'new tabpage' },
    },
    p = { -- nvim-projectconfig
      name = 'project related',
      c = { '<cmd>lua require("nvim-projectconfig").edit_project_config()<CR>' , 'edit project config' },
    },
    q = { '<cmd>Wquit<CR>', 'close current window' },
    w = { '<cmd>call win#Win()<CR>', 'win mode'}, -- vim-win
    z = { 'MaximizerToggle<CR>', 'toggle maximizing current window' }, -- maximizer
  }, { prefix = '<leader>' })

  require('plugins.fugitive').mappings()
  require('plugins.coc-nvim').mappings()
  require('plugins.telescope').mappings()
  require('plugins.notify').mappings()

end

return M
