return {
  -- lsps目录下的插件配置
  require('plugins.lsps.coc-nvim'),
  require('plugins.lsps.nvim-treesitter'),
  -- 自动标签
  {
    'windwp/nvim-ts-autotag',
    dependencies = { 'nvim-treesitter/nvim-treesitter' },
  },
  -- Treesitter文本对象
  {
    'nvim-treesitter/nvim-treesitter-textobjects',
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
  },

  -- Treesitter重构
  {
    'nvim-treesitter/nvim-treesitter-refactor',
    dependencies = { 'nvim-treesitter/nvim-treesitter' },
  },

  -- Rainbow括号
  {
    'p00f/nvim-ts-rainbow',
    dependencies = { 'nvim-treesitter/nvim-treesitter' },
  },
  -- 撤销树
  {
    'mbbill/undotree',
    cmd = { 'UndotreeToggle' },
  },
}
