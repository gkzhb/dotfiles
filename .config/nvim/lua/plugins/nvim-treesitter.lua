local M = {}

function M.init()
  require('nvim-treesitter.configs').setup({
    ensure_installed = {
      'bash',
      'c',
      'cpp',
      'cmake',
      'comment',
      'css',
      'dockerfile',
      'fish',
      'git_rebase',
      'gitattributes',
      'gitcommit',
      'gitignore',
      'go',
      'html',
      'java',
      'javascript',
      'jsdoc',
      'jsonc',
      'latex',
      'lua',
      'org',
      'php',
      'python',
      'query',
      'rust',
      'scss',
      'toml',
      'tsx',
      'typescript',
      'vim',
      'vue',
      'yaml',
      'markdown',
    }, -- one of "all", "maintained" (parsers with maintainers), or a list of languages
    ignore_install = {}, -- List of parsers to ignore installing
    highlight = {
      enable = true, -- false will disable the whole extension
      disable = {}, -- list of language that will be disabled
      -- Setting this to true will run `:h syntax` and tree-sitter at the same time.
      -- Set this to `true` if you depend on 'syntax' being enabled (like for indentation).
      -- Using this option may slow down your editor, and you may see some duplicate highlights.
      -- Instead of true it can also be a list of languages
      additional_vim_regex_highlighting = false,
    },
    indent = {
      enable = true,
    },
    playground = {
      enable = true,
      disable = {},
      updatetime = 25, -- Debounced time for highlighting nodes in the playground from source code
      persist_queries = false, -- Whether the query persists across vim sessions
      keybindings = {
        toggle_query_editor = 'o',
        toggle_hl_groups = 'i',
        toggle_injected_languages = 't',
        toggle_anonymous_nodes = 'a',
        toggle_language_display = 'I',
        focus_language = 'f',
        unfocus_language = 'F',
        update = 'R',
        goto_node = '<cr>',
        show_help = '?',
      },
    },
    context_commentstring = {
      enable = true,
    },
    textobjects = {
      select = {
        enable = true,
        lookahead = true,
      },
      move = {
        enable = true,
        set_jumps = true,
        goto_next_start = {
          [']m'] = '@function.outer',
          [']]'] = '@class.outer',
        },
        goto_next_end = {
          [']M'] = '@function.outer',
          [']['] = '@class.outer',
        },
        goto_previous_start = {
          ['[m'] = '@function.outer',
          ['[['] = '@class.outer',
        },
        goto_previous_end = {
          ['[M'] = '@function.outer',
          ['[]'] = '@class.outer',
        },
      },
    },
    -- pairs = { -- nvim-treesitter-pairs
    --   enable = true,
    --   disable = { 'lua' },
    --   keymaps = {
    --     goto_partner = '%',
    --   },
    -- },
    matchup = { -- vim-matchup
      enable = true,
    },
    refactor = {
      highlight_definitions = { enable = false },
      highlight_current_scope = { enable = false },
    },
    autotag = { -- windwp/nvim-ts-autotag
      enable = true,
    },
    rainbow = { -- nvim-ts-rainbow
      enable = true,
      disable = { 'jsx', 'tsx' },
    },
  })

  vim.opt.foldmethod = 'expr'
  vim.wo.foldexpr = 'luaeval("require\'nvim-treesitter.fold\'.get_fold_indic(vim.v.lnum)")'
end

return M
