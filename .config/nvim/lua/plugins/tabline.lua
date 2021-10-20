local M = {}
function M.init()
  require('tabline').setup({
    enable = false,
    options = {
      show_tabs_always = true,
      show_bufnr = true,
    }
  })
end
return M
