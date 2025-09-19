local M = {}

function M.init()
  require('toggleterm').setup({})
end

function M.mappings()
  local wk = require('which-key')
  wk.register({
    t = { '<cmd>exe v:count1 . "ToggleTerm"<CR>', 'toggle term [n]' },
    a = { '<cmd>ToggleTermToggleAll<CR>', 'toggle all term' },
  }, { mode = 'n', prefix = '<Leader>o' })
end

return M
