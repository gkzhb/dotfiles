-- vim: set fdm=marker:
-- {{{1 Packer managed plugins
return require('packer').startup({function()
  -- Packer itself
  use 'wbthomason/packer.nvim'

  -- {{{2 dependencies
  use 'kyazdani42/nvim-web-devicons'
  use 'nvim-lua/plenary.nvim'
  use 'tami5/sqlite.lua'
  use 'voldikss/vim-floaterm'
  use {
    'norcalli/nvim-terminal.lua',
    config = function() require('terminal').setup() end
  }

  -- {{{2 performance
  use 'dstein64/vim-startuptime'
  -- use cache to speed up lua module loading
  use 'lewis6991/impatient.nvim'

  -- {{{2 color theme
  use {
    'olimorris/onedarkpro.nvim',
    config = require('plugins.onedarkpro').init,
  }
  -- {{{2 display enhancement
  use {
    'karb94/neoscroll.nvim',
    config = require('plugins.neoscroll').init
  }
  use {
    'folke/which-key.nvim',
    config = require('plugins.which-key').init
  }
  -- greeter
  use {
      'goolord/alpha-nvim',
      requires = { 'nvim-web-devicons' },
      config = require('plugins.alpha-greeter').init
  }
  use {
    'lukas-reineke/indent-blankline.nvim',
    event = 'BufRead',
    config = require('plugins.indent-blankline').init
  }
  -- beautify notifications
  use {
    'rcarriga/nvim-notify',
    config = require('plugins.notify').init,
  }
  -- show colors
  use {
    'norcalli/nvim-colorizer.lua',
    config = require('plugins.colorizer').init
  }
  -- set foldtext
  use {
    'scr1pt0r/crease.vim',
    config = require('plugins.crease').init
  }
  -- status line and tab line
  use {
    'akinsho/bufferline.nvim',
    config = require('plugins.bufferline').init,
    after = 'onedarkpro.nvim'
  }
  use {
    'windwp/windline.nvim',
    config = require('plugins.windline').init
  }
  -- file explorer
  use {
    'ptzz/lf.vim',
    requires = { 'vim-floaterm' },
    setup = require('plugins.lf').setup
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
  use {
    'mbbill/undotree',
    cmd = { 'UndotreeToggle' },
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
  use {
    'dstein64/vim-win',
    config = require('plugins.vim-win').init
  }
  use 'ggandor/lightspeed.nvim'
  use 'szw/vim-maximizer'
  -- {{{2 edit
  -- use {
  --   'tpope/vim-surround',
  --   keys = {'c', 'd', 'y'}
  -- }
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
  use 'honza/vim-snippets' -- coc-snippets needs snippets
  -- treesitter
  use {
    'nvim-treesitter/nvim-treesitter',
    run = ':TSUpdateSync',
    config = require('plugins.nvim-treesitter').init
  }
  use {
    'nvim-treesitter/nvim-treesitter-textobjects',
  }
  use {
    'JoosepAlviste/nvim-ts-context-commentstring',
    event = 'BufRead',
  }
  use {
    'nvim-treesitter/playground'
  }
  use 'andymass/vim-matchup'  -- support tree-sitter

  -- coc.nvim provides rename and highlight current symbol
  use { 'nvim-treesitter/nvim-treesitter-refactor' }

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

  -- {{{2 search: telescope related
  use {
    'nvim-telescope/telescope.nvim',
    requires = { 'plenary.nvim' },
    config = require('plugins.telescope').init
  }
  use {
    'nvim-telescope/telescope-fzf-native.nvim',
    run = 'make',
    after = 'telescope.nvim',
    config = function() require('telescope').load_extension('fzf') end
  }
  use {
    'TC72/telescope-tele-tabby.nvim',
    after = 'telescope.nvim',
    config = function() require('telescope').load_extension('tele_tabby') end
  }
  use {
    'camgraff/telescope-tmux.nvim',
    after = 'telescope.nvim',
    requires = 'nvim-terminal.lua',
    config = function() require('telescope').load_extension('tmux') end
  }
  use {
    'nvim-telescope/telescope-project.nvim',
    after = 'telescope.nvim'
  }
  use {
    'sudormrfbin/cheatsheet.nvim',
    config = require('plugins.cheatsheet').init
  }
  use {
    'AckslD/nvim-neoclip.lua',
    requires = { 'sqlite.lua' },
    after = 'telescope.nvim',
    config = require('plugins.neoclip').init
  }
  use {
    'nvim-telescope/telescope-frecency.nvim',
    config = function() require('telescope').load_extension('frecency') end,
    requires = { 'sqlite.lua' }
  }
  use {
    'Shatur/neovim-session-manager',
    config = require('plugins.session-manager').init,
    requires = { 'telescope.nvim', 'plenary.nvim' }
  }
  use {
    'fannheyward/telescope-coc.nvim',
    after = 'telescope.nvim',
    config = function() require('telescope').load_extension('coc') end
  }
  -- {{{2 others
  use {
    'glacambre/firenvim',
    run = function() vim.fn['firenvim#install'](0) end,
    config = require('plugins.firenvim').init
  }
  -- https://github.com/neovim/neovim/issues/12587
  use 'antoinemadec/FixCursorHold.nvim' -- TODO(remove this): temporarily fix CursorHold not triggerred
end,
  config = {
    compile_path = vim.fn.stdpath('config')..'/lua/packer_compiled.lua',
    display = {
      open_fn = require('packer.util').float
    }
}})
