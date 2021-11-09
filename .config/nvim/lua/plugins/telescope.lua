local M = {}

function M.init()
  require('telescope').setup({
    defaults = {
      mappings = {
        i = {
          ['C-q'] = require('telescope.actions').close,
        },
        n = {
          ['q'] = require('telescope.actions').close,
        },
      },
    },
    extensions = {
      tele_tabby = {
        use_highlight = true,
      },
    },
  })
end

function M.mappings()
  local map = require('utils').map
  local wk = require('which-key')
  wk.register({
    s = {
      name = 'telescope search',
      f = { '<cmd>lua require("telescope.builtin").find_files()<cr>', 'files' },
      g = { '<cmd>lua require("telescope.builtin").live_grep()<cr>', 'grep content'},
      b = { '<cmd>lua require("telescope.builtin").buffers()<cr>', 'buffers' },
      h = { '<cmd>lua require("telescope.builtin").help_tags()<cr>', 'help tags' },
      l = { '<cmd>lua require("telescope.builtin").resume()<cr>', 'last view' },

      c = { '<cmd>lua require("telescope").extensions.cheatsheet.cheatsheet()<cr>', 'cheatsheet' },
      p = { '<cmd>lua require("telescope").extensions.project.project{}<cr>', 'project' },
      t = { '<cmd>lua require("telescope").extensions.tele_tabby.list()<cr>', 'current tabs' },
      y = { '<cmd>lua require("telescope").extensions.neoclip.default()<cr>', 'clipboard' },
      w = { '<cmd>lua require("telescope").extensions.tmux.windows({})<cr>', 'tmux win' },
      s = { '<cmd>lua require("telescope").extensions.sessions.sessions()<cr>', 'sessions' },
      r = { '<cmd>lua require("telescope").extensions.frecency.frecency()<cr>', 'recent files' },
    },
  }, { prefix = '<leader>'})
end

return M
