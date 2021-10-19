local M = {}

function M.init()
end

function FugitiveAfterGit()
  if not vim.fn.exists('*FugitiveResult') then
    return
  end
  local result = vim.fn.FugitiveResult()
  if not vim.fn.filereadable(result.file or '') or (result.args and result.args[0] or '') ~= 'commit' or not result.exit_status then
    return
  end
  vim.cmd([[Gsplit -]])
end

vim.cmd([[
  augroup FugitiveRelated
    autocmd!
    autocmd User FugitiveChanged call v:lua.FugitiveAfterGit()
  augroup END
]])

return M

