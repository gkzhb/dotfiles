local M = {}

function M.init()
  local notify = require('notify')
  notify.setup({
    stages = 'fade',
    render = 'default',
    background_colour = '#000000',
  })
  vim.notify = notify
end

function M.mappings()
  local wk = require('which-key')
  wk.register({
    [','] = {
      '<cmd>lua require("notify").dismiss()<CR>',
      'close all notifications'
    }
  }, { prefix = '<leader>' })
end

return M
