return {
  'rcarriga/nvim-notify',
  keys = {
    { '<leader>nc', '<cmd>lua require("notify").dismiss()<CR>', desc = 'close all notifications' },
    { '<leader>nl', '<cmd>Notifications<CR>', desc = 'list all notifications' },
    { '<leader>n', group = 'notifications' },
  },
  lazy = false,
  config = function()
    local notify = require('notify')
    notify.setup({
      stages = 'static',
      render = 'default',
      background_colour = '#000000',
    })
    vim.notify = notify
  end,
}
