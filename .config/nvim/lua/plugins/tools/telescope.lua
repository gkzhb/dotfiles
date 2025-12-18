local M = {
  'nvim-telescope/telescope.nvim',
  dependencies = { 'nvim-lua/plenary.nvim' },
  cmd = 'Telescope',
  keys = {
    -- Basic telescope commands
    -- { '<leader>ff', '<cmd>Telescope find_files<cr>', desc = 'Find Files' },
    -- { '<leader>fg', '<cmd>Telescope live_grep<cr>', desc = 'Live Grep' },

    -- Telescope search menu
    { '<leader>sa', '<cmd>lua require("telescope.builtin").commands()<cr>', desc = 'Search Commands' },
    { '<leader>sb', '<cmd>lua require("telescope.builtin").buffers()<cr>', desc = 'Search Buffers' },
    { '<leader>sf', '<cmd>lua require("telescope.builtin").find_files()<cr>', desc = 'Search Files' },
    { '<leader>sg', '<cmd>lua require("telescope.builtin").live_grep()<cr>', desc = 'Search Grep Content' },
    { '<leader>sh', '<cmd>lua require("telescope.builtin").help_tags()<cr>', desc = 'Search Help Tags' },
    { '<leader>sj', '<cmd>lua require("telescope.builtin").jumplist()<cr>', desc = 'Search Jump List' },
    { '<leader>sk', '<cmd>lua require("telescope.builtin").loclist()<cr>', desc = 'Search Location List' },
    { '<leader>sl', '<cmd>lua require("telescope.builtin").resume()<cr>', desc = 'Search Last View' },
    { '<leader>sz', '<cmd>lua require("telescope.builtin").autocommands()<cr>', desc = 'Search Autocommands' },

    -- Git related
    { '<leader>svc', '<cmd>lua require("telescope.builtin").git_commits()<cr>', desc = 'Search Git Commits' },
    { '<leader>svb', '<cmd>lua require("telescope.builtin").git_bcommits()<cr>', desc = "Search Buffer's Git Commits" },

    -- Coc related
    { '<leader>sca', '<cmd>lua require("telescope").extensions.coc.code_actions()<cr>', desc = 'Search Code Actions' },
    { '<leader>scc', '<cmd>lua require("telescope").extensions.coc.commands({})<cr>', desc = 'Search Commands' },
    { '<leader>sccc', '<cmd>lua require("telescope").extensions.coc.coc({})<cr>', desc = 'Search Coc Subcommands' },
    { '<leader>scd', '<cmd>lua require("telescope").extensions.coc.definitions({})<cr>', desc = 'Search Definitions' },
    { '<leader>scdd', '<cmd>lua require("telescope").extensions.coc.diagnostics({})<cr>', desc = 'Search Diagnostics' },
    {
      '<leader>scdw',
      '<cmd>lua require("telescope").extensions.coc.workspace_diagnostics({})<cr>',
      desc = 'Search Workspace Diagnostics',
    },
    {
      '<leader>sci',
      '<cmd>lua require("telescope").extensions.coc.implementations({})<cr>',
      desc = 'Search Implementations',
    },
    { '<leader>scj', '<cmd>lua require("telescope").extensions.coc.locations({})<cr>', desc = 'Search Locations' },
    { '<leader>scl', '<cmd>lua require("telescope").extensions.coc.links({})<cr>', desc = 'Search Links' },
    {
      '<leader>scs',
      '<cmd>lua require("telescope").extensions.coc.document_symbols({})<cr>',
      desc = 'Search Document Symbols',
    },
    {
      '<leader>scsw',
      '<cmd>lua require("telescope").extensions.coc.workspace_symbols({})<cr>',
      desc = 'Search Workspace Symbols',
    },
    {
      '<leader>scrr',
      '<cmd>lua require("telescope").extensions.coc.references({ initial_mode = "normal"})<cr>',
      desc = 'Search References',
    },
    {
      '<leader>scru',
      '<cmd>lua require("telescope").extensions.coc.references_used({})<cr>',
      desc = 'Search References(Used)',
    },
    { '<leader>scre', '<cmd>lua require("telescope").extensions.coc.mru({})<cr>', desc = 'Search MRU' },

    -- Extensions
    {
      '<leader>se',
      '<cmd>lua require("telescope").extensions.cheatsheet.cheatsheet()<cr>',
      desc = 'Search Cheatsheet',
    },
    { '<leader>sn', '<cmd>lua require("telescope").extensions.notify.notify()<cr>', desc = 'Search Notifications' },
    { '<leader>sp', '<cmd>lua require("telescope").extensions.project.project{}<cr>', desc = 'Search Project' },
    { '<leader>sr', '<cmd>lua require("telescope").extensions.ast_grep.ast_grep()<cr>', desc = 'Search Recent Files' },
    { '<leader>ss', '<cmd>SessionManager load_session<cr>', desc = 'Search Sessions' },
    { '<leader>st', '<cmd>lua require("telescope").extensions.tele_tabby.list()<cr>', desc = 'Search Tabs' },
    { '<leader>sw', '<cmd>lua require("telescope").extensions.tmux.windows({})<cr>', desc = 'Search Tmux Windows' },
    { '<leader>sy', '<cmd>lua require("telescope").extensions.neoclip.default()<cr>', desc = 'Search Clipboard' },

    -- Deep search
    { '<leader>sdb', '<cmd>lua require("telescope.builtin").builtin()<cr>', desc = 'Search Builtin Pickers' },
    { '<leader>sdp', '<cmd>lua require("telescope.builtin").pickers()<cr>', desc = 'Search Previous Pickers' },
    { '<leader>sdr', '<cmd>lua require("telescope.builtin").registers()<cr>', desc = 'Search Registers' },
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

return M
