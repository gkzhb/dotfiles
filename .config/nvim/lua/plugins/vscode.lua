local M = {}
function M.init()
  require('vscode').setup({ transparent = true, })
  require('vscode').load()
end

return M
