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
      fzf = {
        fuzzy = true,
        override_generic_sorter = true,
        override_file_sorter = true,
        case_mode = 'smart_case',
      },
      tele_tabby = {
        use_highlight = true,
      },
    },
  })
end

function M.mappings()
  local wk = require('which-key')
  wk.register({
    s = {
      name = 'telescope search',
      f = { '<cmd>lua require("telescope.builtin").find_files()<cr>', 'files' },
      g = { '<cmd>lua require("telescope.builtin").live_grep()<cr>', 'grep content' },
      b = { '<cmd>lua require("telescope.builtin").buffers()<cr>', 'buffers' },
      h = { '<cmd>lua require("telescope.builtin").help_tags()<cr>', 'help tags' },
      l = { '<cmd>lua require("telescope.builtin").resume()<cr>', 'last view' },

      c = { '<cmd>lua require("telescope").extensions.cheatsheet.cheatsheet()<cr>', 'cheatsheet' },
      p = { '<cmd>lua require("telescope").extensions.project.project{}<cr>', 'project' },
      t = { '<cmd>lua require("telescope").extensions.tele_tabby.list()<cr>', 'current tabs' },
      y = { '<cmd>lua require("telescope").extensions.neoclip.default()<cr>', 'clipboard' },
      w = { '<cmd>lua require("telescope").extensions.tmux.windows({})<cr>', 'tmux win' },
      s = { '<cmd>SessionManager load_session<cr>', 'sessions' },
      r = { '<cmd>lua require("telescope").extensions.frecency.frecency()<cr>', 'recent files' },
      n = { '<cmd>lua require("telescope").extensions.notify.notify()<cr>', 'notification history' },
    },
  }, { prefix = '<leader>' })
end

return M
