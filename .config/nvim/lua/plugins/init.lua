-- vim: set fdm=marker:
vim.cmd [[packadd packer.nvim]]

-- {{{1 Packer managed plugins
return require('packer').startup(function()
  -- Packer itself
  use 'wbthomason/packer.nvim'

  -- {{{2 performance
  use 'dstein64/vim-startuptime'

  -- {{{2 color theme
  use 'navarasu/onedark.nvim'
  -- {{{2 language related TODO
  use 'tpope/vim-commentary'
  -- {{{2 display enhancement TODO
  use {
    'karb94/neoscroll.nvim',
    config = require('plugins.neoscroll').init
  }
  use {
    'liuchengxu/vim-which-key'
  }
  use 'mhinz/vim-startify'
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
  use {
    'hoob3rt/lualine.nvim',
    requires = { { 'kyazdani42/nvim-web-devicons', opt = true } },
    config = require('plugins.lualine').init
  }
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
  use 'christoomey/vim-tmux-navigator'
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
    requires = { {'nvim-lua/plenary.nvim'} }
  }
  use {
    'folke/trouble.nvim',
    requires = 'kyazdani42/nvim-web-devicons',
    config = require('plugins.trouble').init
  }
  use {
    'https://gitlab.com/yorickpeterse/nvim-pqf.git',
    config = require('plugins.pqf').init
  }
end)
