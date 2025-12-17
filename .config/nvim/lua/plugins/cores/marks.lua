-- vim标记增强
local M = {
  'chentoast/marks.nvim',
}

function M.config()
  require('marks').setup({
    mappings = {
      annotate = 'm/',
      preview = 'm;',
    },
  })
end

return M
