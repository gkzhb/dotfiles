local M = {
  'lukas-reineke/indent-blankline.nvim',
  dependencies = { 'Mofiqul/vscode.nvim' },
}

function M.config()
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
