local M = {
  'sudormrfbin/cheatsheet.nvim',
  dependencies = { 'nvim-telescope/telescope.nvim' },
}

function M.config()
  require('cheatsheet').setup({})
end

return M
