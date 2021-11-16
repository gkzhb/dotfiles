local M = {}

function M.init()
  require('session_manager').setup({
    autoload_mode = require('session_manager.config').AutoloadMode.CurrentDir,
  })
  require('telescope').load_extension('sessions')
end

return M
