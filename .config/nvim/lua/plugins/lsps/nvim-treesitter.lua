-- Treesitter
local M = {
  'nvim-treesitter/nvim-treesitter',
  lazy = false,
  build = ':TSUpdate',
  branch = 'main',
}

function M.config()
  local ts = require('nvim-treesitter')
  local langs = {
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
    -- 'org',
    'php',
    'python',
    'query',
    'rust',
    'scss',
    'thrift',
    'toml',
    'tsx',
    'typescript',
    'vim',
    'vue',
    'yaml',
    'markdown',
  }
  ts.install(langs)
  -- require('nvim-treesitter.configs').setup({
  --   ensure_installed = {
  --   },                   -- one of "all", "maintained" (parsers with maintainers), or a list of languages
  --   highlight = {
  --     enable = true,     -- false will disable the whole extension
  --     disable = {},      -- list of language that will be disabled
  --     -- Setting this to true will run `:h syntax` and tree-sitter at the same time.
  --     -- Set this to `true` if you depend on 'syntax' being enabled (like for indentation).
  --     -- Using this option may slow down your editor, and you may see some duplicate highlights.
  --     -- Instead of true it can also be a list of languages
  --     additional_vim_regex_highlighting = false,
  --   },
  --   indent = {
  --     enable = true,
  --   },
  --   textobjects = {
  --     select = {
  --       enable = true,
  --       lookahead = true,
  --     },
  --     move = {
  --       enable = true,
  --       set_jumps = true,
  --       goto_next_start = {
  --         [']m'] = '@function.outer',
  --         [']]'] = '@class.outer',
  --       },
  --       goto_next_end = {
  --         [']M'] = '@function.outer',
  --         [']['] = '@class.outer',
  --       },
  --       goto_previous_start = {
  --         ['[m'] = '@function.outer',
  --         ['[['] = '@class.outer',
  --       },
  --       goto_previous_end = {
  --         ['[M'] = '@function.outer',
  --         ['[]'] = '@class.outer',
  --       },
  --     },
  --   },
  -- })

  vim.opt.foldmethod = 'expr'
  vim.opt.foldexpr = 'v:lua.vim.treesitter.foldexpr()'
  vim.opt.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
  -- vim.wo.foldexpr = 'v:lua.vim.treesitter.foldexpr()'
end

return M
