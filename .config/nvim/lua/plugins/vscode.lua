local M = {}
function M.init()
  local c = require('vscode.colors').get_colors()
  require('vscode').setup({ transparent = false, group_overrides = {
    CursorLine = { bg = c.vscLeftMid },
  } })
  require('vscode').load()
end

return M
