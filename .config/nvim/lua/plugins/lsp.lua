return {
  -- lsps目录下的插件配置
  require('plugins.lsps.coc-nvim'),
  require('plugins.lsps.nvim-treesitter'),
  require('plugins.lsps.treesitter-modules'),
  -- 自动 tag 标签配对补全
  -- Refer to https://github.com/Rekwass/Dotfiles/blob/da25b84a33eb785480abc5b54e0e610c3358fa0c/nvim/lua/plugins/ts-autotag.nvim.lua
  {
    'tronikelis/ts-autotag.nvim',
    lazy = false,
    opts = {
      opening_node_types = {
        -- templ
        'tag_start',
        -- xml,
        'STag',
        -- html
        'start_tag',
        -- jsx
        'jsx_opening_element',
      },
      identifier_node_types = {
        -- html
        'tag_name',
        'erroneous_end_tag_name',
        -- xml,
        'Name',
        -- jsx
        'member_expression',
        'identifier',
        -- templ
        'element_identifier',
      },
      disable_in_macro = true,
      auto_close = {
        enabled = true,
      },
      auto_rename = {
        enabled = true,
        closing_node_types = {
          -- jsx
          'jsx_closing_element',
          -- xml,
          'Etag',
          -- html
          'end_tag',
          'erroneous_end_tag',
          -- templ
          'tag_end',
        },
      },
    },
  },
  -- Treesitter文本对象
  {
    'nvim-treesitter/nvim-treesitter-textobjects',
    branch = 'main',
    init = function()
      -- Disable entire built-in ftplugin mappings to avoid conflicts.
      -- See https://github.com/neovim/neovim/tree/master/runtime/ftplugin for built-in ftplugins.
      vim.g.no_plugin_maps = true

      -- Or, disable per filetype (add as you like)
      -- vim.g.no_python_maps = true
      -- vim.g.no_ruby_maps = true
      -- vim.g.no_rust_maps = true
      -- vim.g.no_go_maps = true
    end,
    dependencies = { 'nvim-treesitter/nvim-treesitter' },
  },
  -- 上下文注释
  {
    'JoosepAlviste/nvim-ts-context-commentstring',
    dependencies = { 'nvim-treesitter/nvim-treesitter' },
    event = 'BufRead',
    config = function()
      vim.g.skip_ts_context_commentstring_module = true
    end,
  },
  -- TODO ts-comments.nvim ?

  -- 匹配高亮
  {
    'andymass/vim-matchup',
    dependencies = { 'nvim-treesitter/nvim-treesitter' },
    init = function()
      -- Fix conflicts with coc.nvim
      -- Refer to https://github.com/andymass/vim-matchup/issues/67
      vim.g.matchup_matchparen_nomode = 'i'
    end,
    opts = {
      treesitter = {
        stopline = 2000,
      },
    },
  },

  -- @deprecated Treesitter重构
  -- {
  --   'nvim-treesitter/nvim-treesitter-refactor',
  --   dependencies = { 'nvim-treesitter/nvim-treesitter' },
  -- },

  -- @deprecated Rainbow括号
  -- {
  --   'p00f/nvim-ts-rainbow',
  --   dependencies = { 'nvim-treesitter/nvim-treesitter' },
  -- },

  {
    'https://gitlab.com/HiPhish/rainbow-delimiters.nvim',
    dependencies = { 'nvim-treesitter/nvim-treesitter' },
  },

  -- 撤销树
  {
    'mbbill/undotree',
    cmd = { 'UndotreeToggle' },
  },
}
