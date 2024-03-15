local M = {}

function M.setup()
  require('mappings').init()
end

function M.init()
  require('which-key').setup({})
  require('mappings').setMappings()
end

return M
