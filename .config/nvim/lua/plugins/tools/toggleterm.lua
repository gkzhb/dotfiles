local M = {
  'akinsho/toggleterm.nvim',
  keys = {
    { '<Leader>ot', '<cmd>exe v:count1 . "ToggleTerm"<CR>', desc = 'toggle term [n]', mode = 'n' },
    { '<Leader>oa', '<cmd>ToggleTermToggleAll<CR>', desc = 'toggle all term', mode = 'n' },
  },
}

function M.config()
  require('toggleterm').setup({})
end

return M
