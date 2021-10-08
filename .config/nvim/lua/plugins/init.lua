-- vim: set fdm=marker: 
vim.cmd [[packadd packer.nvim]]

-- {{{1 Packer managed plugins
return require('packer').startup(function(use)
  -- Packer itself
  use 'wbthomason/packer.nvim'

  -- {{{2 color theme
  use 'joshdick/onedark.vim'
  -- {{{2 language related TODO
  use 'tpope/vim-commentary'
  -- {{{2 display enhancement TODO
  use 'karb94/neoscroll.nvim'
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
  -- use 'voldikss/vim-floaterm'
  use {
    'ptzz/lf.vim',
    requires = { { 'voldikss/vim-floaterm' } },
    setup = require('plugins.lf').setup
  }
  use {
    'Shougo/denite.nvim',
    run = ':UpdateRemotePlugins'
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
      'Gedit'
    },
    ft = {'fugitive'}
  }
  use 'junegunn/gv.vim' -- git commit browser
  use 'sodapopcan/vim-twiggy' -- git branch push/pull/rebase

  -- {{{2 language related
  -- treesitter
  use {
    'nvim-treesitter/nvim-treesitter',
    run = ':TSUpdate',
    config = require('plugins.nvim-treesitter').init
  }
  use {
    'JoosepAlviste/nvim-ts-context-commentstring',
    event = 'BufRead',
  }
  use {
    'nvim-treesitter/playground'
  }
  -- lsp client
  use {
    'neoclide/coc.nvim',
    branch = 'release',
    config = require('plugins.coc-nvim').init
  }
  use 'kevinoid/vim-jsonc'
end)
