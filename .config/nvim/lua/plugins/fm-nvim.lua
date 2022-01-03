local M = {}

function M.init()
  require('fm-nvim').setup({
    ui = {
      float = {
        border = 'rounded',
      },
    },
  })
end

return M
