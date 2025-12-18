return {
  'mrjones2014/legendary.nvim',
  keys = {
    { '<leader>si', '<cmd>Legendary<CR>', desc = 'search keymaps, cmds, autocmds' },
  },
  config = function()
    require('legendary').setup({})
  end,
}
