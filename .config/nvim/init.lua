-- {{{1 for vscode neovim
if vim.g.vscode then
  -- VSCode Neovim
  require('user.vscode')
  return
end

-- for Ordinary Neovim
-- {{{1 Load Local Configuration
-- load local vim config file `.config/nvim/customize.vim`
local utils = require('utils')
local localConfig = require('utils.local-config')
localConfig.initLocalConfig()
localConfig.loadHooks()
localConfig.runHook(localConfig.HookNames.beforeAll)
-- {{{1 basic config
utils.loadModuleSafely('basic-setup')

-- load pckr plugins
utils.loadModuleSafely('plugins')
-- plugins and configs are in 'lua/plugins/init.lua'
-- }}}
utils.loadModuleSafely('autocommands')

-- {{{1 file type
vim.cmd([[
  autocmd BufNewFile,BufRead *.mdx :set filetype=markdown
]])
-- }}}
-- {{{1 afterAll hook
localConfig.runHook(localConfig.HookNames.afterAll)
-- vim: set fdm=marker:
