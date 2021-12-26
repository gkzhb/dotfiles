local M = {}

-- Pipe precommit log into a new buffer
-- > from https://github.com/tpope/vim-fugitive/issues/1854
function FugitiveAfterGit()
  if not vim.fn.exists('*FugitiveResult') then
    return
  end
  local result = vim.fn.FugitiveResult()
  if not vim.fn.filereadable(result.file or '')
      or (result.args and result.args[0] or '') ~= 'commit'
      or not result.exit_status then
    return
  end
  vim.cmd([[Gsplit -]])
end

function M.init()
  vim.cmd([[
    augroup FugitiveRelated
      autocmd!
      autocmd User FugitiveChanged call v:lua.FugitiveAfterGit()
    augroup END
  ]])
end

function M.mappings()
  local wk = require('which-key')
  wk.register({
    g = {
      name = 'git related',
      s = { '<cmd>G<CR>', 'git status' },
      b = { '<cmd>G blame<CR>', 'git blame' },
      ['<Space>'] = { ':G<Space>', 'git command', silent = false },
    }
  }, { prefix = '<leader>' })
end

return M
