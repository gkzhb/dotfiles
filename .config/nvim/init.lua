-- vim: set fdm=marker:
-- {{{1 basic config
pcall(require, 'vim-basic')
local mappings = require('mappings')
pcall(mappings.init)
-- {{{1 plugins
-- check packer installation and load packer
local packerPath = vim.fn.stdpath('data') .. '/site/pack/packer/start/packer.nvim'
if vim.fn.empty(vim.fn.glob(packerPath)) > 0 then
  vim.api.nvim_echo({{'Installing packer.nvim', 'Type'}}, true, {})
  local packerGitUrl = 'https://github.com/wbthomason/packer.nvim'
  local installPackerCmd = string.format('10split |term git clone --depth=1 %s %s', packerGitUrl, packerPath)
  vim.api.nvim_command(installPackerCmd)
end

-- load 'impatient' to cache lua
-- use 'pcall' to avoid crash when 'impatient' is not installed by packer
pcall(require, 'impatient')
-- load packer plugins
require('plugins')
pcall(require, 'packer_compiled') -- load packer lua cache
-- plugins and configs are in 'lua/plugins/init.lua'
-- }}}
-- {{{1 Keyboard Mappings/Bindings & Shortcuts
pcall(mappings.setMappings)

-- {{{1 Load Local Configuration
-- load local vim config file `.config/nvim/customize.vim`
local customizeFile = vim.fn.expand(vim.fn.stdpath('config') .. '/customize.lua')
if vim.fn.filereadable(customizeFile) > 0 then
  vim.cmd('source ' .. customizeFile)
end
