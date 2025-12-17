local M = {
  'folke/which-key.nvim',
  dependencies = { 'legendary.nvim' },
}

function M.config()
  require('mappings').init()
  require('which-key').setup({})
  require('mappings').setMappings()
end

return M
