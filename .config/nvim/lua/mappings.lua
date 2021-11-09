local M = {}
local utils = require('utils')
local map = utils.map

function SetTab(size)
  vim.opt.tabstop = size
  vim.opt.softtabstop = size
  vim.opt.shiftwidth = size
end

function M.init()
  -- leader key
  vim.g.mapleader=' '
  vim.g.maplocalleader=' '
  vim.opt.ttimeout=true
  vim.opt.tm=500
end

function M.setMappings()
  -- TODO: register map with which-key.nvim and add comments for mappings

  -- fugitive
  map('n', '<leader>g', ':G<CR>')
  map('n', '<leader>g<Space>', ':G<Space>', { silent = false })

  -- choosewin
  map('n', '-', '<Plug>(choosewin)', { noremap = false, silent = true })

  -- lf
  map('n', '<leader>lf', ':Lf<CR>')

  -- maximizer
  map('n', '<leader>z', ':MaximizerToggle<CR>')

  -- buffer actions
  map('n', '<C-N>', ':bnext<CR>')
  map('n', '<C-P>', ':bprev<CR>')
  -- [n]gb switch to buffer [n]
  map('n', 'gb', 'v:lua.switchBuffer(v:count)', { expr = true })

  -- tab actions
  map('n', '<leader>tn', '<cmd>TablineTabNew<CR>')
  map('n', '<leader>tr', ':<C-u>TablineTabRename ')
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
  -- project actions
  map('n', '<leader>pc', '<cmd>lua require("nvim-projectconfig").edit_project_config()<CR>')

  require('plugins.coc-nvim').mappings()
  require('plugins.telescope').mappings()

end

-- switch current active buffer to buffer number c
function switchBuffer(c)
  if c > 0 and vim.fn.bufnr(c) > -1 then
    return utils.esc(':<C-U>' .. c .. 'b<CR>')
  end
  return ''
end

return M
