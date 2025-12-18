-- Git集成
local M = {
  'tpope/vim-fugitive',
  cmd = {
    'G',
    'Git',
    'Gdiffsplit',
    'Gread',
    'Gwrite',
    'Ggrep',
    'GMove',
    'GDelete',
    'GBrowse',
    'GRemove',
    'GRename',
    'Glgrep',
    'Gedit',
    'Gclog',
  },
  ft = { 'fugitive' },
}

-- Pipe precommit log into a new buffer
-- > from https://github.com/tpope/vim-fugitive/issues/1854
function FugitiveAfterGit()
  if not vim.fn.exists('*FugitiveResult') then
    return
  end
  local result = vim.fn.FugitiveResult()
  if
    not vim.fn.filereadable(result.file or '')
    or (result.args and result.args[0] or '') ~= 'commit'
    or not result.exit_status
  then
    return
  end
  vim.cmd([[Gsplit -]])
end

function M.config()
  vim.cmd([[
    augroup FugitiveRelated
      autocmd!
      autocmd User FugitiveChanged call v:lua.FugitiveAfterGit()
    augroup END
  ]])
end

M.keys = {
  { '<leader>g', group = 'git related' },
  { '<leader>gs', '<cmd>G<CR>', desc = 'git status' },
  { '<leader>gb', '<cmd>G blame<CR>', desc = 'git blame' },
  { '<leader>g<Space>', ':G<Space>', desc = 'git command', silent = false },
}

return M
