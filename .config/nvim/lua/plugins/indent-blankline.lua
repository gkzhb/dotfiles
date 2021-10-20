local M = {}

function M.init()
  require('indent_blankline').setup({
    char = '▏',
    filetype_exclude = {'help', 'terminal', 'dashboard', 'alpha'},
    buftype_exclude = {'terminal'},
    show_trailing_blankline_indent = false,
    show_first_indent_level = false
  })
end

return M
