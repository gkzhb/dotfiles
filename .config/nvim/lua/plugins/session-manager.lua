local M = {}

function M.init()
  require('session_manager').setup({
    autoload_last_session = false,
  })
  require('telescope').load_extension('sessions')
end

return M
