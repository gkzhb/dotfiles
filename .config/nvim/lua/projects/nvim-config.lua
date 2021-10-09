-- neovim config project
local M = {}

function M.init()
  -- load lua-dev in coc-lua
  local luadev = require('lua-dev').setup({})
  vim.fn['coc#config']('Lua', luadev)
end

return M
