local M = {}

function M.init()
  require('ibl').setup({
    indent = {
      char = { '|', '¦', '┆', '┊' }, -- '▏'
    },
    scope = {
      highlight = { 'MyIblScope' },
    },
    exclude = {
      filetypes = { 'help', 'terminal', 'dashboard', 'alpha' },
      buftypes = { 'terminal' },
    },
  })
end

return M
