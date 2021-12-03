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

function M.init()
  -- leader key
  vim.g.mapleader=' '
  vim.g.maplocalleader=' '
  vim.opt.ttimeout=true
  vim.opt.tm=500
end

function M.setMappings()
  local wk = require('which-key')
  -- TODO: register map with which-key.nvim and add comments for mappings

  -- fugitive
  map('n', '<leader>g', ':G<CR>')
  map('n', '<leader>g<Space>', ':G<Space>', { silent = false })

  -- choosewin
  map('n', '-', '<Plug>(choosewin)', { noremap = false, silent = true })

  -- lf
  map('n', '<leader>d', ':Lf<CR>')

  -- maximizer
  map('n', '<leader>z', ':MaximizerToggle<CR>')

  -- buffer actions
  map('n', '<C-N>', ':bnext<CR>')
  map('n', '<C-P>', ':bprev<CR>')
  -- [n]gb switch to buffer [n]
  map('n', 'gb', 'v:lua.SwitchBuffer(v:count)', { expr = true })

  -- tab actions
  map('n', '<leader>tn', '<cmd>tabnew<CR>')
  -- map('n', '<leader>tr', ':<C-u>TablineTabRename ')
  -- tabline.nvim
  -- map('n', 'gt', '<cmd>TablineBufferNext<CR>')
  -- map('n', 'gT', '<cmd>TablineBufferPrevious<CR>')
  
  -- quick actions
  map('n', '<leader>w', ':w<CR>')
  map('n', '<leader>q', ':Wquit<CR>')
  map('n', '<leader>cp', ':set invpaste<CR>')
  map('n', '<leader>ci', ':set list!<CR>')
  map('n', '<leader>ch', ':noh<CR>')

  map('n', '<leader>ct4', ':call v:lua.SetTab(4)<CR>')
  map('n', '<leader>ct2', ':call v:lua.SetTab(2)<CR>')
  -- show highlight
  wk.register({
    h = {
      name = 'show highlight',
      s = { '<cmd>lua SynGroup()<CR>', 'get SynGroup' },
      ss = { '<cmd>lua SynStack()<CR>', 'get SynStack' },
      t = { '<cmd>TSHighlightCapturesUnderCursor<CR>', 'get treesitter highlight' },
    }
  }, { prefix = '<leader>' })
  -- project actions
  map('n', '<leader>pc', '<cmd>lua require("nvim-projectconfig").edit_project_config()<CR>')

  require('plugins.coc-nvim').mappings()
  require('plugins.telescope').mappings()
  require('plugins.notify').mappings()

end

-- switch current active buffer to buffer number c
function _G.SwitchBuffer(c)
  if c > 0 and vim.fn.bufnr(c) > -1 then
    return utils.esc(':<C-U>' .. c .. 'b<CR>')
  end
  return ''
end

return M
