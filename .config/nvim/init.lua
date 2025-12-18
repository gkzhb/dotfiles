-- {{{1 for vscode neovim
if vim.g.vscode then
  -- VSCode Neovim
  require('user.vscode')
  return
end

-- for Ordinary Neovim
-- {{{1 hide which-key warnings
-- from https://github.com/LazyVim/LazyVim/discussions/4008
-- filter which-key warnings
local orig_notify = vim.notify
vim.notify = function(msg, level, opts)
  if msg:match('which%-key') and level == vim.log.levels.WARN then
    return
  end
  orig_notify(msg, level, opts)
end

-- {{{1 Load Local Configuration
-- load local vim config file `.config/nvim/customize.vim`
local utils = require('utils')
local localConfig = require('utils.local-config')
localConfig.initLocalConfig()
localConfig.loadHooks()
localConfig.runHook(localConfig.HookNames.beforeAll)

-- {{{1 basic config
utils.loadModuleSafely('basic-setup')

-- 加载Lazy.nvim
require('config.lazy')

-- {{{1 autocommands
utils.loadModuleSafely('autocommands')

-- {{{1 afterAll hook
localConfig.runHook(localConfig.HookNames.afterAll)
-- vim: set fdm=marker:
