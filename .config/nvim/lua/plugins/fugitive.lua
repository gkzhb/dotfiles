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

return M
