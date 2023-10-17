local M = {}

M.packerPath = vim.fn.stdpath('data') .. '/pckr/pckr.nvim'
M.pluginPath = vim.fn.stdpath('data') .. '/site/pack/pckr/opt'

--- Check whether packer exists
--- @return boolean boolean true if packer exists
function M.checkPackerExist()
  return vim.loop.fs_stat(M.packerPath)
end

--- Install packer with git
function M.installPacker()
  vim.api.nvim_echo({ { 'Installing pckr.nvim', 'Type' } }, true, {})
  local packerGitUrl = 'https://github.com/lewis6991/pckr.nvim'
  local installPackerCmd = string.format('10split |term git clone --filter=blob:none --depth=1 %s %s', packerGitUrl, M.packerPath)
  vim.api.nvim_command(installPackerCmd)
end

function M.init()
  if not M.checkPackerExist() then
    M.installPacker()
  end
  vim.opt.rtp:prepend(M.packerPath)
end

return M
