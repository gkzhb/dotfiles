return {
  -- 依赖项
  'kyazdani42/nvim-web-devicons',
  'nvim-lua/plenary.nvim',
  'tami5/sqlite.lua',

  -- cores目录下的插件配置
  require('plugins.cores.alpha-greeter'),
  require('plugins.cores.bufferline'),
  require('plugins.cores.indent-blankline'),
  require('plugins.cores.legendary'),
  require('plugins.cores.marks'),
  require('plugins.cores.notify'),
  require('plugins.cores.ufo'),
  require('plugins.cores.vscode'),
  require('plugins.cores.which-key'),
  require('plugins.cores.windline'),

  -- 终端颜色高亮
  {
    'norcalli/nvim-terminal.lua',
    config = function()
      require('terminal').setup()
    end,
  },

  -- snacks.nvim
  {
    'folke/snacks.nvim',
    config = function()
      require('snacks').setup({
        input = { enabled = true },
        picker = { enabled = true },
        terminal = { enabled = true },
      })
    end,
  },

  -- 性能监控
  'dstein64/vim-startuptime',

  -- UI增强
  {
    'stevearc/dressing.nvim',
    config = function()
      require('dressing').setup({
        select = {
          enabled = false,
        },
      })
    end,
  },

  -- 状态列
  {
    'luukvbaal/statuscol.nvim',
    config = function()
      local builtin = require('statuscol.builtin')
      require('statuscol').setup({
        relculright = true,
        segments = {
          {
            text = { '%s' },
            click = 'v:lua.ScSa',
            sign = { name = { '.*' }, maxwidth = 3 },
          },
          { text = { builtin.lnumfunc, ' ' }, click = 'v:lua.ScLa' },
          { text = { builtin.foldfunc, ' ' }, click = 'v:lua.ScFa' },
        },
      })
    end,
  },

  -- 缓冲区作用域
  {
    'tiagovla/scope.nvim',
    config = function()
      require('scope').setup()
    end,
  },

  -- 文件管理器
  {
    'mikavilpas/yazi.nvim',
    config = function()
      vim.g.loaded_netrwPlugin = 1
    end,
  },

  -- nvim-tree
  {
    'kyazdani42/nvim-tree.lua',
    config = function()
      -- require('nvim-tree').setup({})
    end,
  },
  {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "MunifTanjim/nui.nvim",
      "nvim-tree/nvim-web-devicons", -- optional, but recommended
    },
    lazy = false, -- neo-tree will lazily load itself
  },
}
