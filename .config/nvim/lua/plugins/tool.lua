return {
  -- tools目录下的插件配置
  require('plugins.tools.cheatsheet'),
  require('plugins.tools.fzf'),
  require('plugins.tools.neoclip'),
  require('plugins.tools.opencode'),
  require('plugins.tools.codebridge'),
  require('plugins.tools.session-manager'),
  require('plugins.tools.spectre'),
  require('plugins.tools.telescope'),
  require('plugins.tools.toggleterm'),
  require('plugins.tools.orgmode'),
  require('plugins.tools.window-picker'),

  -- Grug Far
  {
    'MagicDuck/grug-far.nvim',
    config = function()
      require('grug-far').setup({
        startInInsertMode = false,
      })
    end,
    keys = {
      { '<leader>st', '<cmd>lua require("grug-far").open()<CR>', desc = 'GrugFar Search' },
    },
  },

  -- Telescope扩展
  {
    'nvim-telescope/telescope-ui-select.nvim',
    dependencies = { 'nvim-telescope/telescope.nvim' },
    config = function()
      require('telescope').load_extension('ui-select')
    end,
  },

  {
    'Marskey/telescope-sg',
  },

  -- {
  --   'nvim-telescope/telescope-fzf-native.nvim',
  --   build = 'make',
  --   dependencies = { 'nvim-telescope/telescope.nvim' },
  --   config = function()
  --     require('telescope').load_extension('fzf')
  --   end,
  -- },
  {
    'alexpasmantier/tv.nvim',
    keys = {
      { '<leader>tv',  ':Tv<Space>',                      desc = 'Television cli' },
      { '<leader>fvd', '<cmd>Tv git-changed-files<CR>', desc = "Git changed files" },
    }
  },

  {
    'TC72/telescope-tele-tabby.nvim',
    dependencies = { 'nvim-telescope/telescope.nvim' },
    config = function()
      require('telescope').load_extension('tele_tabby')
    end,
  },

  {
    'camgraff/telescope-tmux.nvim',
    dependencies = { 'nvim-telescope/telescope.nvim', 'norcalli/nvim-terminal.lua' },
    config = function()
      require('telescope').load_extension('tmux')
    end,
  },

  {
    'nvim-telescope/telescope-project.nvim',
    dependencies = { 'nvim-telescope/telescope.nvim' },
  },

  -- Telescope coc集成
  {
    'fannheyward/telescope-coc.nvim',
    dependencies = { 'nvim-telescope/telescope.nvim' },
    config = function()
      require('telescope').load_extension('coc')
    end,
  },

  -- 自动缩进检测
  {
    'nmac427/guess-indent.nvim',
    config = function()
      require('guess-indent').setup({})
    end,
  },
}
