local M = {
  'nvim-telescope/telescope.nvim',
  dependencies = { 'nvim-lua/plenary.nvim' },
  cmd = 'Telescope',
  keys = {
    { '<leader>ff', '<cmd>Telescope find_files<cr>', desc = 'Find Files' },
    { '<leader>fg', '<cmd>Telescope live_grep<cr>', desc = 'Live Grep' },
  },
}

function M.config()
  local telescope_actions = require('telescope.actions.set')
  -- From https://github.com/David-Kunz/vim/blob/master/init.lua#L164
  -- Fix treesitter not loaded when opening file from telescope
  -- Related issues:
  -- https://github.com/nvim-telescope/telescope.nvim/issues/559
  -- https://github.com/nvim-telescope/telescope.nvim/issues/699
  local fixfolds = {
    hidden = true,
    attach_mappings = function(_)
      telescope_actions.select:enhance({
        post = function()
          vim.cmd(':normal! zx')
        end,
      })
      return true
    end,
  }
  local actions = require('telescope.actions')

  require('telescope').setup({
    pickers = {
      buffers = fixfolds,
      find_files = fixfolds,
      git_files = fixfolds,
      grep_string = fixfolds,
      live_grep = fixfolds,
      oldfiles = fixfolds,
    },
    defaults = {
      -- https://github.com/nvim-telescope/telescope.nvim/blob/master/lua/telescope/mappings.lua
      mappings = {
        i = {
          ['<C-S-q>'] = actions.send_selected_to_qflist + actions.open_qflist,
          ['<M-q>'] = nil,
          ['<C-c>'] = nil,
          ['<C-k>'] = nil,

          ['<C-u>'] = actions.preview_scrolling_up,
          ['<C-d>'] = actions.preview_scrolling_down,
          ['<C-h>'] = actions.preview_scrolling_left,
          ['<C-l>'] = actions.preview_scrolling_right,

          ['<PageUp>'] = actions.results_scrolling_up,
          ['<PageDown>'] = actions.results_scrolling_down,
          ['<C-b>'] = actions.results_scrolling_up,
          ['<C-f>'] = actions.results_scrolling_down,
          ['<M-f>'] = nil, -- actions.results_scrolling_left,
          ['<M-k>'] = nil, -- actions.results_scrolling_right,

          ['<C-;>'] = actions.complete_tag,
        },
        n = {
          ['<leader>qs'] = actions.send_selected_to_qflist + actions.open_qflist,

          ['<C-h>'] = actions.preview_scrolling_left,
          ['<C-l>'] = actions.preview_scrolling_right,
          ['<C-u>'] = actions.preview_scrolling_up,
          ['<C-d>'] = actions.preview_scrolling_down,

          ['H'] = actions.results_scrolling_left,
          ['L'] = actions.results_scrolling_right,
          ['<C-b>'] = actions.results_scrolling_up,
          ['<C-f>'] = actions.results_scrolling_down,
          ['<leader>u'] = actions.results_scrolling_up,
          ['<leader>d'] = actions.results_scrolling_down,
        },
      },
      dynamic_preview_title = true,
    },
    extensions = {
      fzf = {
        fuzzy = true,
        override_generic_sorter = true,
        override_file_sorter = true,
        case_mode = 'smart_case',
      },
      frecency = {
        db_safe_mode = false,
      },
      tele_tabby = {
        use_highlight = true,
      },
      ast_grep = {
        command = {
          'sg', -- For Linux, use `ast-grep` instead of `sg`
          '--json=stream',
        }, -- must have --json=stream
        grep_open_files = false, -- search in opened files
        lang = nil, -- string value, specify language for ast-grep `nil` for default
      },
    },
  })
end

function M.mappings()
  local wk = require('which-key')
  wk.register({
    s = {
      name = 'telescope search',
      a = { '<cmd>lua require("telescope.builtin").commands()<cr>', 'commands' },
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
        b = { '<cmd>lua require("telescope.builtin").git_bcommits()<cr>', "buffer's git commits" },
      },
      z = { '<cmd>lua require("telescope.builtin").autocommands()<cr>', 'autocommands' },

      -- telescope-coc.nvim
      c = {
        name = 'coc related',
        a = { '<cmd>lua require("telescope").extensions.coc.code_actions()<cr>', 'cursor code actions' },
        c = { '<cmd>lua require("telescope").extensions.coc.commands({})<cr>', 'commands' },
        cc = { '<cmd>lua require("telescope").extensions.coc.coc({})<cr>', 'coc subcommands' },
        d = { '<cmd>lua require("telescope").extensions.coc.definitions({})<cr>', 'definitions' },
        dd = { '<cmd>lua require("telescope").extensions.coc.diagnostics({})<cr>', 'diagnostics' },
        dw = {
          '<cmd>lua require("telescope").extensions.coc.workspace_diagnostics({})<cr>',
          'workspace diagnostics',
        },
        i = { '<cmd>lua require("telescope").extensions.coc.implementations({})<cr>', 'implementations' },
        j = { '<cmd>lua require("telescope").extensions.coc.locations({})<cr>', 'locations' },
        l = { '<cmd>lua require("telescope").extensions.coc.links({})<cr>', 'links' },
        s = { '<cmd>lua require("telescope").extensions.coc.document_symbols({})<cr>', 'document symbols' },
        sw = { '<cmd>lua require("telescope").extensions.coc.workspace_symbols({})<cr>', 'workspace symbols' },
        rr = {
          '<cmd>lua require("telescope").extensions.coc.references({ initial_mode = "normal"})<cr>',
          'references',
        },
        ru = { '<cmd>lua require("telescope").extensions.coc.references_used({})<cr>', 'references(used)' },
        re = { '<cmd>lua require("telescope").extensions.coc.mru({})<cr>', 'mru' },
      },

      e = { '<cmd>lua require("telescope").extensions.cheatsheet.cheatsheet()<cr>', 'cheatsheet' },
      n = { '<cmd>lua require("telescope").extensions.notify.notify()<cr>', 'notification history' },
      p = { '<cmd>lua require("telescope").extensions.project.project{}<cr>', 'project' },
      r = { '<cmd>lua require("telescope").extensions.ast_grep.ast_grep()<cr>', 'recent files' },
      -- r = { '<cmd>lua require("telescope").extensions.frecency.frecency()<cr>', 'recent files' },
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
