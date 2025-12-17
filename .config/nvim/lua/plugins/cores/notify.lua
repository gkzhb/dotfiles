local M = {
  'rcarriga/nvim-notify',
}

function M.config()
  local notify = require('notify')
  notify.setup({
    stages = 'static',
    render = 'default',
    background_colour = '#000000',
  })
  vim.notify = notify
end

function M.mappings()
  local wk = require('which-key')
  wk.register({
    n = {
      name = 'notifications',
      c = {
        '<cmd>lua require("notify").dismiss()<CR>',
        'close all notifications',
      },
      l = {
        '<cmd>Notifications<CR>',
        'list all notifications',
      },
    },
  }, { prefix = '<leader>' })
end

return M
