local M = {}

function M.init()
  require('alpha').setup(require('alpha.themes.startify').opts)
end

return M
