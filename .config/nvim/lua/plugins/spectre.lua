local M = {}

function M.init() end

function M.mappings()
  local wk = require('which-key')
  wk.register({
    S = { '<cmd>lua require("spectre").toggle()<CR>', 'Search' },
  }, { prefix = '<leader>', mode = 'n' })
end

return M
