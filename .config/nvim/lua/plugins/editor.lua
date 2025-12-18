return {
  -- editors目录下的插件配置
  require('plugins.editors.fugitive'),
  require('plugins.editors.projectconfig'),
  require('plugins.editors.suda'),

  -- 移动增强
  {
    'ggandor/leap.nvim',
    config = function()
      vim.keymap.set({ 'n', 'x', 'o' }, 's', '<Plug>(leap)')
    end,
  },

  -- 窗口最大化
  'szw/vim-maximizer',

  -- 导航增强
  'tpope/vim-unimpaired',

  -- Tmux导航
  {
    'numToStr/Navigator.nvim',
    config = function()
      require('Navigator').setup()
      vim.keymap.set({ 'n', 't' }, '<C-h>', '<CMD>NavigatorLeft<CR>')
      vim.keymap.set({ 'n', 't' }, '<C-l>', '<CMD>NavigatorRight<CR>')
      vim.keymap.set({ 'n', 't' }, '<C-k>', '<CMD>NavigatorUp<CR>')
      vim.keymap.set({ 'n', 't' }, '<C-j>', '<CMD>NavigatorDown<CR>')
    end,
  },

  -- 编辑增强
  'tpope/vim-surround',
  'tpope/vim-repeat',
  'tpope/vim-commentary',

  {
    'windwp/nvim-autopairs',
    config = function()
      require('nvim-autopairs').setup({
        enable_check_bracket_line = false,
        check_ts = true,
        ts_config = {},
      })
    end,
  },

  -- 代码片段
  'honza/vim-snippets',

  -- 文档生成
  {
    'danymat/neogen',
    config = function()
      require('neogen').setup({})
    end,
    dependencies = { 'nvim-treesitter/nvim-treesitter' },
    keys = {
      { '<leader>/', group = 'generate doc comment' },
      { '<leader>/f', '<cmd>Neogen func<CR>', desc = 'function doc comment' },
      { '<leader>/c', '<cmd>Neogen class<CR>', desc = 'class doc comment' },
      { '<leader>/t', '<cmd>Neogen type<CR>', desc = 'type doc comment' },
    },
  },

  -- 大小写转换
  {
    'johmsalas/text-case.nvim',
    config = function()
      require('textcase').setup({})
    end,
  },

  -- 单词移动增强
  {
    'chaoren/vim-wordmotion',
    config = function()
      -- do not replace default vim word motions, add prefix 'X' instead
      vim.g.wordmotion_prefix = 'X'
    end,
  },

  -- Git分支图
  {
    'rbong/vim-flog',
    cmd = { 'Flog', 'Flogsplit' },
    dependencies = { 'vim-fugitive' },
  },
}
