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
  vim.opt.ttimeout = true
  vim.opt.tm = 500
end

function _G.CopyBufFilePath()
  vim.fn.setreg('+', vim.fn.expand('%:.'))
end

function _G.CopyFileLocation()
  local file_path = vim.fn.expand('%:.')

  -- Check current mode
  local current_mode = vim.api.nvim_get_mode().mode

  if current_mode:find('[vV]') then
    -- Visual mode: get selection range
    local start_pos, end_pos

    start_pos = vim.fn.getpos('v')
    end_pos = vim.fn.getpos('.')

    -- Determine which position comes first and assign accordingly
    if start_pos[2] > end_pos[2] or (start_pos[2] == end_pos[2] and start_pos[3] > end_pos[3]) then
      -- start_pos is after end_pos, swap them
      start_pos, end_pos = end_pos, start_pos
    end
    local line_start = start_pos[2]
    local line_end = end_pos[2]
    local col_start = start_pos[3]
    local col_end = end_pos[3]

    if current_mode == 'V' then
      -- Line selection mode, whole line selection, use xxx-xxxx format
      local location = string.format('%s:%d-%d', file_path, line_start, line_end)
      vim.fn.setreg('+', location)
      print('Copied: ' .. location)
      return
    end

    local location = string.format('%s:%d:%d-%d:%d', file_path, line_start, col_start, line_end, col_end)
    vim.fn.setreg('+', location)
    print('Copied: ' .. location)
    return
  else
    -- Normal mode: current cursor position
    local cursor = vim.api.nvim_win_get_cursor(0)
    local line = cursor[1]
    local col = cursor[2] + 1 -- nvim uses 0-based column
    local location = string.format('%s:%d:%d', file_path, line, col)
    vim.fn.setreg('+', location)
    print('Copied: ' .. location)
  end
end

function M.setMappings()
  local wk = require('which-key')

  -- set yank to system clipboard
  wk.register({
    y = { '"+y', 'yank to clipboard' },
    Y = { '<cmd>lua CopyFileLocation()<CR>', 'copy file location' },
  }, { mode = { 'n', 'v' }, prefix = '<leader>' })
  -- remap <C-a> incremeting number
  wk.register({
    ['<C-s>'] = { '<C-a>', 'increment number' },
  }, { mode = 'n' })
  vim.cmd([[vmap g<C-s> g<C-a>]])
  -- terminal mode mappings
  wk.register({
    ['<C-q>'] = { '<cmd>stopinsert<CR>', 'quit terminal mode' },
  }, { mode = 't', noremap = true, silent = true })

  wk.register({
    -- buffer actions
    ['<C-N>'] = { ':bnext<CR>', 'next buffer' },
    ['<C-P>'] = { ':bprev<CR>', 'previous buffer' },
  }, { mode = 'n' })

  -- quick actions
  wk.register({
    b = {
      name = 'buffer',
      b = { '<cmd>lua require("fzf-lua").buffers()<CR>', 'find buffers' },
      d = { '<cmd>bd<CR>', 'close buffer' },
      s = { '<cmd>w<CR>', 'save buffer' },
      y = { '<cmd>lua CopyBufFilePath()<CR>', 'copy file path' },
      l = { '<cmd>lua CopyFileLocation()<CR>', 'copy file location' },
    },
    t = {
      name = 'toggle config',
      i = { '<cmd>set list!<CR>', 'toggle showing space chars' },
      h = { '<cmd>noh<CR>', 'toggle search highlight' },
      p = { '<cmd>set invpaste<CR>', 'toggle paste mode' },
      s = { '<cmd>call v:lua.ToggleShowSpace()<CR>)', 'toggle showing space char' },
      t4 = { '<cmd>call v:lua.SetTab(4)<CR>', 'set tab size to 4' },
      t2 = { '<cmd>call v:lua.SetTab(2)<CR>', 'set tab size to 2' },
      c = {
        name = 'lazy related',
        i = { '<cmd>Lazy<CR>', 'lazy plugin manager' },
        s = { '<cmd>Lazy sync<CR>', 'sync plugins' },
        p = { '<cmd>Lazy profile<CR>', 'profile plugins' },
      },
    },
    h = { -- highlight related
      name = 'show highlight',
      s = { '<cmd>lua SynGroup()<CR>', 'get SynGroup' },
      ss = { '<cmd>lua SynStack()<CR>', 'get SynStack' },
      t = { '<cmd>TSHighlightCapturesUnderCursor<CR>', 'get treesitter highlight' },
      r = { '<cmd>write | edit | TSBufEnable highlight<CR>', 'refresh treesitter highlight' },
    },
    ['<tab>'] = {
      name = 'tab actions',
      n = { '<cmd>tabnew<CR>', 'new tabpage' },
      d = { '<cmd>tabclose<CR>', 'delete this tabpage' },
    },
    o = {
      name = 'open',
      d = {
        '<cmd>NvimTreeToggle<CR>',
        'toggle nvim tree',
      },
    },
    p = { -- nvim-projectconfig
      name = 'project related',
      c = { '<cmd>lua require("nvim-projectconfig").edit_project_config()<CR>', 'edit project config' },
    },
    -- q = { '<cmd>Wquit<CR>', 'close current window' }, -- for windline float statusline
    q = { '<cmd>q<CR>', 'close current window' },
    r = { '<cmd>registers<CR>', 'show all registers' },
    z = { '<cmd>MaximizerToggle<CR>', 'toggle maximizing current window' }, -- maximizer
  }, { prefix = '<leader>' })

  require('plugins.lsps.coc-nvim').mappings()

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
