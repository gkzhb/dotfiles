local M = {
  'Shatur/neovim-session-manager',
  dependencies = { 'nvim-telescope/telescope.nvim', 'nvim-lua/plenary.nvim' },
}

function M.config()
  require('session_manager').setup({
    autoload_mode = require('session_manager.config').AutoloadMode.Disabled,
  })
end

return M
