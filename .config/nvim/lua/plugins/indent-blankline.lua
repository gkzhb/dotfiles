local M = {}

function M.init()
  vim.g.indent_blankline_char_list = {'|', '¦', '┆', '┊'}
  require('indent_blankline').setup({
    char = '▏',
    filetype_exclude = {'help', 'terminal', 'dashboard', 'alpha'},
    buftype_exclude = {'terminal'},
    show_trailing_blankline_indent = false,
    show_first_indent_level = false,
    show_current_context = true,
    show_current_context_start = true,
  })
end

return M
