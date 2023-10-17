local M = {}

function M.init()
  -- vim.g.indent_blankline_char_list = { '|', '¦', '┆', '┊' }
  require('ibl').setup({
    -- char = '▏',
    -- show_first_indent_level = false, -- ibl.hooks.builtin.hide_first_space_indent_level
    exclude = {
      filetypes = { 'help', 'terminal', 'dashboard', 'alpha' },
      buftypes = { 'terminal' },
    },
  })
end

return M
