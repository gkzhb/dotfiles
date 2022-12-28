local M = {}
local utils = require('utils')

function _G.ToggleShowSpace()
  if vim.opt.listchars:get().space then
    vim.opt.listchars:remove('space')
    vim.opt.listchars:remove('eol')
  else
    vim.opt.listchars:append('space:⋅')
    vim.opt.listchars:append('eol:↴')
  end
end

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
  vim.g.mapleader = ' '
  vim.g.maplocalleader = ' '
  vim.opt.ttimeout = true
  vim.opt.tm = 500
end

function M.setMappings()
  local wk = require('which-key')

  -- terminal mode mappings
  wk.register({
    ['<C-q>'] = { '<cmd>stopinsert<CR>', 'quit terminal mode' },
    ['<C-h>'] = {'<cmd>lua require("tmux").move_left()<CR>', 'move to left' },
    ['<C-j>'] = {'<cmd>lua require("tmux").move_bottom()<CR>', 'move to bottom' },
    ['<C-k>'] = {'<cmd>lua require("tmux").move_top()<CR>', 'move to top' },
    ['<C-l>'] = {'<cmd>lua require("tmux").move_right()<CR>', 'move to right' },
  }, { mode = 't', noremap = true, silent = true })

  wk.register({
    ['-'] = { '<Plug>(choosewin)', 'choose win', noremap = false, silent = true }, -- choosewin
    -- buffer actions
    ['<C-N>'] = { ':bnext<CR>', 'next buffer' },
    ['<C-P>'] = { ':bprev<CR>', 'previous buffer' },
  }, { mode = 'n' })

  -- quick actions
  wk.register({
    b = {
      name = 'buffer',
      b = { '<cmd>lua require("fzf-lua").buffers()<CR>', 'find buffers' },
      s = { '<cmd>w<CR>', 'save buffer' },
    },
    c = {
      name = 'config',
      i = { '<cmd>set list!<CR>', 'toggle showing space chars' },
      h = { '<cmd>noh<CR>', 'toggle search highlight' },
      p = { '<cmd>set invpaste<CR>', 'toggle paste mode' },
      s = { '<cmd>call v:lua.ToggleShowSpace()<CR>)', 'toggle showing space char' },
      t4 = { '<cmd>call v:lua.SetTab(4)<CR>', 'set tab size to 4' },
      t2 = { '<cmd>call v:lua.SetTab(2)<CR>', 'set tab size to 2' },
      c = {
        name = 'packer related',
        c = { '<cmd>PackerCompile<CR>', 'packer compile' },
        s = { '<cmd>PackerSync<CR>', 'packer sync plugins' },
      },
    },
    d = { '<cmd>lua require("fm-nvim").Lf(vim.fn.glob("%:p"))<CR>', 'open lf with current buffer file selected' }, -- lf, select current buffer file
    D = { '<cmd>lua require("fm-nvim").Lf()<CR>', 'open lf' }, -- lf, open cwd
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
      c = { '<cmd>lua require("nvim-projectconfig").edit_project_config()<CR>', 'edit project config' },
    },
    -- q = { '<cmd>Wquit<CR>', 'close current window' }, -- for windline float statusline
    q = { '<cmd>q<CR>', 'close current window' },
    z = { '<cmd>MaximizerToggle<CR>', 'toggle maximizing current window' }, -- maximizer
  }, { prefix = '<leader>' })

  require('plugins.legendary').mappings()
  require('plugins.fugitive').mappings()
  require('plugins.coc-nvim').mappings()
  require('plugins.vim-win').mappings()
  require('plugins.telescope').mappings()
  require('plugins.notify').mappings()
  require('plugins.toggleterm').mappings()
  wk.register({
    ['/'] = { -- Neogen
      name = 'generate doc comment',
      f = { '<cmd>Neogen func<CR>', 'function doc comment' },
      c = { '<cmd>Neogen class<CR>', 'class doc comment' },
      t = { '<cmd>Neogen type<CR>', 'type doc comment' },
    },
    a = {
      '<cmd>NvimTreeToggle<CR>',
      'toggle nvim tree',
    },
  }, { mode = 'n', prefix = '<Leader>' })
  wk.register({ -- fzf-lua mappings
    name = 'fzf search',
    b = { '<cmd>lua require("fzf-lua").buffers()<CR>', 'find buffers' },
    f = { '<cmd>lua require("fzf-lua").files()<CR>', 'find files' },
    g = { '<cmd>lua require("fzf-lua").grep()<CR>', 'grep' },
    gl = { '<cmd>lua require("fzf-lua").grep_last()<CR>', 'last grep' },
    gb = { '<cmd>lua require("fzf-lua").lgrep_curbuf()<CR>', 'live grep current buffer' },
    gp = { '<cmd>lua require("fzf-lua").live_grep()<CR>', 'live grep current project' },
    l = { '<cmd>lua require("fzf-lua").resume()<CR>', 'resume last findings' },
    a = { '<cmd>lua require("fzf-lua").commands()<CR>', 'search commands' },
    c = { '<cmd>lua require("fzf-lua").changes()<CR>', 'search changes' },
    m = { '<cmd>lua require("fzf-lua").marks()<CR>', 'search marks' },
    k = { '<cmd>lua require("fzf-lua").keymaps()<CR>', 'search keymaps' },
    j = { '<cmd>lua require("fzf-lua").jumps()<CR>', 'search jumps' },
    r = { '<cmd>lua require("fzf-lua").registers()<CR>', 'search registers' },
    h = { '<cmd>lua require("fzf-lua").help_tags()<CR>', 'search help_tags' },
    n = { ':FzfLua ', 'run fzf lua command', silent = false },

    v = {
      name = 'git related',
      c = { '<cmd>lua require("fzf-lua").git_commits()<CR>', 'commits' },
      cb = { '<cmd>lua require("fzf-lua").git_bcommits()<CR>', 'bcommits' },
      b = { '<cmd>lua require("fzf-lua").git_branches()<CR>', 'branches' },
      f = { '<cmd>lua require("fzf-lua").git_files()<CR>', 'files' },
    },
  }, { mode = 'n', prefix = '<Leader>f' })
end

return M
