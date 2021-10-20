-- vim: set fdm=marker:
-- {{{1 Packer managed plugins
return require('packer').startup({function()
  -- Packer itself
  use 'wbthomason/packer.nvim'

  -- {{{2 dependencies
  use 'kyazdani42/nvim-web-devicons'
  use 'nvim-lua/plenary.nvim'

  -- {{{2 performance
  use 'dstein64/vim-startuptime'
  -- use cache to speed up lua module loading
  use 'lewis6991/impatient.nvim'

  -- {{{2 color theme
  use 'navarasu/onedark.nvim'
  -- {{{2 display enhancement
  use {
    'karb94/neoscroll.nvim',
    config = require('plugins.neoscroll').init
  }
  use {
    'liuchengxu/vim-which-key'
  }
  -- use 'mhinz/vim-startify'
  -- greeter
  use {
      'goolord/alpha-nvim',
      requires = { 'nvim-web-devicons' },
      config = require('plugins.alpha-greeter').init
  }
  -- use 'Yggdroot/indentLine'
  use {
    "lukas-reineke/indent-blankline.nvim",
    event = "BufRead",
    config = require('plugins.indent-blankline').init
  }
  -- preview the result of replace command in real time
  -- 实时预览替换命令执行效果
  use 'markonm/traces.vim'
  use { -- set foldtext
    'scr1pt0r/crease.vim',
    config = require('plugins.crease').init
  }
  -- status line
  -- TODO: style tabline and remove lualine
  use {
    'hoob3rt/lualine.nvim',
    requires = { { 'nvim-web-devicons', opt = true } },
    config = require('plugins.lualine').init
  }
  -- global status line
  use {
    'windwp/windline.nvim',
    config = require('plugins.windline').init,
    after = 'lualine.nvim'
  }
  -- tab line
  use {
    'kdheepak/tabline.nvim',
    config = require('plugins.tabline').init
  }
  use {
    'ptzz/lf.vim',
    requires = { { 'voldikss/vim-floaterm' } },
    setup = require('plugins.lf').setup
  }
  use {
    'glacambre/firenvim',
    run = function() vim.fn['firenvim#install'](0) end,
    config = require('plugins.firenvim').init
  }
  -- {{{2 movement
  use {
    'christoomey/vim-tmux-navigator',
    config = require('plugins.tmux-navigator').init
  }
  use {
    't9md/vim-choosewin',
    config = require('plugins.choosewin').init
  }
  use 'easymotion/vim-easymotion'
  use 'szw/vim-maximizer'
  -- {{{2 edit
  use {
    'tpope/vim-surround',
    keys = {'c', 'd', 'y'}
  }
  use {
    'windwp/nvim-projectconfig',
    config = require('plugins.projectconfig').init,
    after = 'coc.nvim'
  }
  use {
    'lambdalisue/suda.vim',
    setup = require('plugins.suda').setup
  }
  -- {{{2 git related
  use {
    'tpope/vim-fugitive', -- vim 中使用 git 的增强插件
    cmd = {
      'G',
      'Git',
      'Gdiffsplit',
      'Gread',
      'Gwrite',
      'Ggrep',
      'GMove',
      'GDelete',
      'GBrowse',
      'GRemove',
      'GRename',
      'Glgrep',
      'Gedit',
      'Gclog'
    },
    ft = {'fugitive'},
    config = require('plugins.fugitive').init
  }
  use 'junegunn/gv.vim' -- git commit browser
  use 'sodapopcan/vim-twiggy' -- git branch push/pull/rebase

  -- {{{2 language related
  use 'tpope/vim-commentary'
  -- treesitter
  use {
    'nvim-treesitter/nvim-treesitter',
    branch = '0.5-compat',
    run = ':TSUpdate',
    config = require('plugins.nvim-treesitter').init
  }
  use {
    'nvim-treesitter/nvim-treesitter-textobjects',
    branch = '0.5-compat'
  }
  use {
    'JoosepAlviste/nvim-ts-context-commentstring',
    event = 'BufRead',
  }
  use {
    'nvim-treesitter/playground'
  }
  -- neovim lua
  use {
    'folke/lua-dev.nvim',
    config = require('plugins.lua-dev').init
  }
  -- lsp client
  use {
    'neoclide/coc.nvim',
    branch = 'release',
    config = require('plugins.coc-nvim').init
  }
  use 'kevinoid/vim-jsonc'

  -- {{{2 search
  use {
    'nvim-telescope/telescope.nvim',
    requires = { 'plenary.nvim' }
  }
  -- pretty list
  use {
    'folke/trouble.nvim',
    requires = 'nvim-web-devicons',
    config = require('plugins.trouble').init
  }
  use {
    'https://gitlab.com/yorickpeterse/nvim-pqf.git',
    config = require('plugins.pqf').init
  }
  -- {{{2 others
  use {
    'Shatur/neovim-session-manager',
    config = require('plugins.session-manager').init,
    requires = { 'telescope.nvim', 'plenary.nvim' }
  }
end,
  config = {
    compile_path = vim.fn.stdpath('config')..'/lua/packer_compiled.lua',
    display = {
      open_fn = function() require('packer.util').float({ border = 'single' }) end,
    }
}})
