-- neovim config project
local M = {}

function M.init()
  -- load lua-dev in coc-lua
  local vimLuaConfig = {
    completion = {
      keywordSnippet = "Disable"
    },
    diagnostics = {
      globals = { 'vim', 'use' },
      disable = { 'lowercase-global', 'different-requires' }
    },
    workspace = {
      checkThirdParty = false,
      library = {
        -- do not load neovim runtime library by default
        [vim.fn.expand("$VIMRUNTIME/lua")] = true,
        [vim.fn.expand("$VIMRUNTIME/lua/vim/lsp")] = true
      }
    }
  }
  local luadev = require('lua-dev').setup({
    lspconfig = vimLuaConfig
  })
  vim.fn['coc#config']('Lua', luadev)
end

return M
