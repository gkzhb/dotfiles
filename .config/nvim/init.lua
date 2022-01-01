-- {{{1 Load Local Configuration
-- load local vim config file `.config/nvim/customize.vim`
local utils = require('utils')
local localConfig = require('utils.local-config')
localConfig.initLocalConfig()
localConfig.loadHooks()
localConfig.runHook(localConfig.HookNames.beforeAll)
-- {{{1 basic config
utils.loadModuleSafely('basic-setup')
local mappings = utils.loadModuleSafely('mappings')
if mappings then
  utils.callFunctionSafely(mappings.init)
end

-- load packer plugins
utils.loadModuleSafely('plugins')
pcall(require, 'packer_compiled') -- load packer lua cache
-- plugins and configs are in 'lua/plugins/init.lua'
-- }}}
-- {{{1 Keyboard Mappings/Bindings & Shortcuts
if mappings then
  utils.callFunctionSafely(mappings.setMappings)
end

-- {{{1 file type
vim.cmd([[
  autocmd BufNewFile,BufRead *.mdx :set filetype=markdown
]])
-- }}}
-- {{{1 afterAll hook
localConfig.runHook(localConfig.HookNames.afterAll)
-- vim: set fdm=marker:
