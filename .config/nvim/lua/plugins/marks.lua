local M = {}

function M.init()
  require('marks').setup({
    mappings = {
      annotate = 'm/',
      preview = 'm;',
    }
  })
end

return M
