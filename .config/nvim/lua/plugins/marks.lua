local M = {}

function M.init()
  require('marks').setup({
    mappings = {
      annotate = 'm/',
    }
  })
end

return M
