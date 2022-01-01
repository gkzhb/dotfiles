local M = {}

M.packerPath = vim.fn.stdpath('data') .. '/site/pack/packer/start/packer.nvim'

--- Check whether packer exists
--- @return boolean boolean true if packer exists
function M.checkPackerExist()
  return vim.fn.empty(vim.fn.glob(M.packerPath)) == 0
end

--- Install packer with git
function M.installPacker()
  vim.api.nvim_echo({{'Installing packer.nvim', 'Type'}}, true, {})
  local packerGitUrl = 'https://github.com/wbthomason/packer.nvim'
  local installPackerCmd = string.format('10split |term git clone --depth=1 %s %s', packerGitUrl, M.packerPath)
  vim.api.nvim_command(installPackerCmd)
end

return M
