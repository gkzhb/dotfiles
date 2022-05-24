local M = {}
function M.init()
  require('tabline').setup({
    enable = true,
    options = {
      -- section_separators = { '%=', '%=' },
      show_tabs_always = true,
      show_bufnr = true,
    },
  })
  vim.cmd([[
    hi link tabline_a_normal WLblack_green_a
    hi link tabline_b_normal WLwhite_green_c
    hi link tabline_c_normal WLgreen_c_NormalBg
    hi link TabLineFill WLgreen_c_NormalBg
  ]])
end
return M
