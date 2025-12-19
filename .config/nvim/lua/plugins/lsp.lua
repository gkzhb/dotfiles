return {
  -- lsps目录下的插件配置
  require('plugins.lsps.coc-nvim'),
  require('plugins.lsps.nvim-treesitter'),
  require('plugins.lsps.treesitter-modules'),
  -- 自动标签
  {
    'windwp/nvim-ts-autotag',
    dependencies = { 'nvim-treesitter/nvim-treesitter' },
    opts = {
      enable_close_on_slash = false,
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

  -- 匹配高亮
  {
    'andymass/vim-matchup',
    dependencies = { 'nvim-treesitter/nvim-treesitter' },
    opts = {
      treesitter = {
        stopline = 800,
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
