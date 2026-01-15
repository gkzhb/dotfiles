local M = {
  's1n7ax/nvim-window-picker',
  name = 'window-picker',
  -- event = 'VeryLazy',
  version = '2.*',
  opts = {
    hint = 'floating-big-letter',
  },
  config = function()
    require('window-picker').setup({
      hint = 'floating-big-letter',
    })
  end,
  keys = {
    {
      '-',
      function()
        local window_picker = require('window-picker')
        local picked_window_id = window_picker.pick_window()
        if picked_window_id then
          vim.api.nvim_set_current_win(picked_window_id)
        end
      end,
      desc = 'Pick window',
      mode = 'n',
    },
  },
}
return M
