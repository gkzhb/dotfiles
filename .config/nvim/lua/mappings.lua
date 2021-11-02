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
  -- which key plugin
  map('n', '<leader>', ':WhichKey "<Space>"<CR>')

  -- fugitive
  map('n', '<leader>g', ':G<CR>')
  map('n', '<leader>g<Space>', ':G<Space>', { silent = false })

  -- choosewin
  map('n', '-', '<Plug>(choosewin)', { noremap = false, silent = true })

  -- lf
  map('n', '<leader>lf', ':Lf<CR>')

  -- maximizer
  map('n', '<leader>z', ':MaximizerToggle<CR>')

  -- tab actions
  map('n', '<leader>tn', '<cmd>TablineTabNew<CR>')
  map('n', '<leader>tr', '<cmd>TablineTabRename ')
  -- tabline.nvim
  -- map('n', 'gt', '<cmd>TablineBufferNext<CR>')
  -- map('n', 'gT', '<cmd>TablineBufferPrevious<CR>')
  -- quick actions
  map('n', '<leader>w', ':w<CR>')
  map('n', '<leader>q', ':Wquit<CR>')
  map('n', '<leader>cp', ':set invpaste<CR>')
  map('n', '<leader>ci', ':set list!<CR>')
  map('n', '<leader>ch', ':noh<CR>')

  map('n', '<C-N>', ':bnext<CR>')
  map('n', '<C-P>', ':bprev<CR>')


  map('n', '<leader>ct4', ':call v:lua.SetTab(4)<CR>')
  map('n', '<leader>ct2', ':call v:lua.SetTab(2)<CR>')
  -- project actions
  map('n', '<leader>pc', '<cmd>lua require("nvim-projectconfig").edit_project_config()<CR>')

  require('plugins.coc-nvim').mappings()

  -- telescope
  map('n', '<leader>sf', '<cmd>lua require("telescope.builtin").find_files()<cr>')
  map('n', '<leader>sg', '<cmd>lua require("telescope.builtin").live_grep()<cr>')
  map('n', '<leader>sb', '<cmd>lua require("telescope.builtin").buffers()<cr>')
  map('n', '<leader>sh', '<cmd>lua require("telescope.builtin").help_tags()<cr>')
  map('n', '<leader>sl', '<cmd>lua require("telescope.builtin").resume()<cr>')

  map('n', '<leader>sc', '<cmd>lua require("telescope").extensions.cheatsheet.cheatsheet()<cr>')
  map('n', '<leader>sp', '<cmd>lua require("telescope").extensions.project.project{}<cr>')
  map('n', '<leader>st', '<cmd>lua require("telescope").extensions.tele_tabby.list()<cr>')
  map('n', '<leader>sy', '<cmd>lua require("telescope").extensions.neoclip.default()<cr>')
  map('n', '<leader>sw', '<cmd>lua require("telescope").extensions.tmux.windows({})<cr>')
  map('n', '<leader>ss', '<cmd>lua require("telescope").extensions.sessions.sessions()<cr>')
  map('n', '<leader>sr', '<cmd>lua require("telescope").extensions.frecency.frecency()<cr>')

end
return M
