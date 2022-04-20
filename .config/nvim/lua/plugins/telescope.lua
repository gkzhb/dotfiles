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
      b = { '<cmd>lua require("telescope.builtin").buffers()<cr>', 'buffers' },
      f = { '<cmd>lua require("telescope.builtin").find_files()<cr>', 'files' },
      g = { '<cmd>lua require("telescope.builtin").live_grep()<cr>', 'grep content' },
      h = { '<cmd>lua require("telescope.builtin").help_tags()<cr>', 'help tags' },
      j = { '<cmd>lua require("telescope.builtin").jumplist()<cr>', 'jump list entries' },
      k = { '<cmd>lua require("telescope.builtin").loclist()<cr>', 'location list' },
      l = { '<cmd>lua require("telescope.builtin").resume()<cr>', 'last view' },
      -- git VCS pickers
      v = {
        name = 'git related',
        c = { '<cmd>lua require("telescope.builtin").git_commits()<cr>', 'git commits' },
        b = { '<cmd>lua require("telescope.builtin").git_bcommits()<cr>', 'buffer\'s git commits' },
      },

      c = { '<cmd>lua require("telescope").extensions.cheatsheet.cheatsheet()<cr>', 'cheatsheet' },
      n = { '<cmd>lua require("telescope").extensions.notify.notify()<cr>', 'notification history' },
      p = { '<cmd>lua require("telescope").extensions.project.project{}<cr>', 'project' },
      r = { '<cmd>lua require("telescope").extensions.frecency.frecency()<cr>', 'recent files' },
      s = { '<cmd>SessionManager load_session<cr>', 'sessions' },
      t = { '<cmd>lua require("telescope").extensions.tele_tabby.list()<cr>', 'current tabs' },
      w = { '<cmd>lua require("telescope").extensions.tmux.windows({})<cr>', 'tmux win' },
      y = { '<cmd>lua require("telescope").extensions.neoclip.default()<cr>', 'clipboard' },

      -- deep keymaps, default telescope pickers
      d = {
        b = { '<cmd>lua require("telescope.builtin").builtin()<cr>', 'builtin pickers' },
        p = { '<cmd>lua require("telescope.builtin").pickers()<cr>', 'previous pickers' },
        r = { '<cmd>lua require("telescope.builtin").registers()<cr>', 'list vim registers' },
      },
    },
  }, { prefix = '<leader>' })
end

return M
