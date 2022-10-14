-- {{{1 Packer managed plugins
return require('packer').startup({
  function(use)
    local cfg = _G.getLocalConfig()
    -- Packer itself
    use('wbthomason/packer.nvim')

    -- {{{2 dependencies
    use('kyazdani42/nvim-web-devicons')
    use('nvim-lua/plenary.nvim')
    use('tami5/sqlite.lua')
    use({ -- hightlight terminal colors
      'norcalli/nvim-terminal.lua',
      config = function()
        require('terminal').setup()
      end,
    })

    -- {{{2 performance
    use('dstein64/vim-startuptime')
    -- use cache to speed up lua module loading
    use('lewis6991/impatient.nvim')

    -- {{{2 color theme
    use({
      'olimorris/onedarkpro.nvim',
      config = require('plugins.onedarkpro').init,
    })
    -- {{{2 display enhancement
    if not _G.getLocalConfig().performantMode then
      use({
        'karb94/neoscroll.nvim',
        config = require('plugins.neoscroll').init,
      })
    end
    use({
      'mrjones2014/legendary.nvim',
      config = require('plugins.legendary').init,
    })
    use({
      'folke/which-key.nvim',
      config = require('plugins.which-key').init,
      after = 'legendary.nvim',
    })
    use({
      'stevearc/dressing.nvim',
      config = function()
        require('dressing').setup({
          select = {
            enabled = false,
          },
        })
      end,
    })
    -- greeter
    use({
      'goolord/alpha-nvim',
      requires = { 'nvim-web-devicons' },
      config = require('plugins.alpha-greeter').init,
    })
    use({
      'lukas-reineke/indent-blankline.nvim',
      event = 'BufRead',
      config = require('plugins.indent-blankline').init,
    })
    -- beautify notifications
    use({
      'rcarriga/nvim-notify',
      config = require('plugins.notify').init,
    })
    -- show colors
    use({
      'norcalli/nvim-colorizer.lua',
      config = require('plugins.colorizer').init,
    })
    -- set foldtext
    use({
      'scr1pt0r/crease.vim',
      config = require('plugins.crease').init,
    })
    -- vim mark enhancement
    use({ 'chentoast/marks.nvim', config = require('plugins.marks').init })
    -- status line and tab line
    use({
      'akinsho/bufferline.nvim',
      branch = 'main',
      config = require('plugins.bufferline').init,
      after = 'onedarkpro.nvim',
    })
    -- improve bufferline.nvim, separate buffers to tabpages
    use({
      'tiagovla/scope.nvim',
      config = function()
        require('scope').setup()
      end,
    })
    use({
      'windwp/windline.nvim',
      config = require('plugins.windline').init,
    })
    -- use {
    --   'rebelot/heirline.nvim',
    --   config = require('plugins.heirline').init
    -- }
    -- file explorer
    use({ -- used for lf
      'is0n/fm-nvim',
      config = require('plugins.fm-nvim').init,
    })
    use({
      'kyazdani42/nvim-tree.lua',
      config = function()
        require('nvim-tree').setup({})
      end,
    })

    use({ 'p00f/nvim-ts-rainbow' })

    -- pretty list
    use({
      'folke/trouble.nvim',
      requires = 'nvim-web-devicons',
      config = require('plugins.trouble').init,
    })
    use({
      'https://gitlab.com/yorickpeterse/nvim-pqf.git',
      config = require('plugins.pqf').init,
    })
    use({
      'mbbill/undotree',
      cmd = { 'UndotreeToggle' },
    })
    -- {{{2 movement
    use({
      'aserowy/tmux.nvim',
      config = function()
        require('tmux').setup({
          copy_sync = { -- sync vim register with tmux clipboard and OS clipboard
            enable = true,
            redirect_to_clipboard = true,
            sync_clipboard = false, -- sync system clipboard with tmux is not working on Mac OS
          },
          navigation = {
            enable_default_keybindings = true,
            persist_zoom = true,
          },
          resize = {
            enable_default_keybindings = false,
          },
        })
      end,
    })
    use({
      't9md/vim-choosewin',
      config = require('plugins.choosewin').init,
    })
    use({
      'dstein64/vim-win',
      config = require('plugins.vim-win').init,
    })
    use('ggandor/lightspeed.nvim')
    use('szw/vim-maximizer')
    use('tpope/vim-unimpaired') -- `[<char>`, `]<char>` related keymappings
    -- {{{2 edit
    use({
      'tpope/vim-surround',
    })
    use({
      'windwp/nvim-projectconfig',
      config = require('plugins.projectconfig').init,
      after = 'coc.nvim',
    })
    use({
      'lambdalisue/suda.vim',
      setup = require('plugins.suda').setup,
    })
    use('tpope/vim-repeat')
    use({
      'windwp/nvim-ts-autotag',
      requires = { 'nvim-treesitter' },
    })

    use('tpope/vim-commentary')
    use('honza/vim-snippets') -- coc-snippets needs snippets

    use({
      'danymat/neogen', -- generate documentation comment for class, function, type
      config = function()
        require('neogen').setup({})
      end,
      requires = { 'nvim-treesitter' },
    })

    -- {{{2 git related
    use({
      'tpope/vim-fugitive', -- git enhancement in vim
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
        'Gclog',
      },
      ft = { 'fugitive' },
      config = require('plugins.fugitive').init,
    })
    -- two below are not working
    -- use 'junegunn/gv.vim' -- git commit browser
    -- use 'sodapopcan/vim-twiggy' -- git branch push/pull/rebase

    -- {{{3 treesitter
    use({
      'nvim-treesitter/nvim-treesitter',
      run = cfg.performantMode and ':TSUpdateSync' or ':TSUpdate',
      config = require('plugins.nvim-treesitter').init,
    })
    use({
      'nvim-treesitter/nvim-treesitter-textobjects',
    })
    use({
      'JoosepAlviste/nvim-ts-context-commentstring',
      event = 'BufRead',
    })
    use({
      'nvim-treesitter/playground',
    })
    -- do not support matchparen highlight paried
    -- use({ 'theHamsta/nvim-treesitter-pairs' })
    -- incompatible with the lua treesitter parser
    use({ 'andymass/vim-matchup', config = require('plugins.matchup').init }) -- support tree-sitter
    -- use { -- get errors in this plugin
    --   'romgrk/nvim-treesitter-context',
    --   config = function() require('treesitter-context').setup({}) end
    -- }

    -- replace default lua treesitter
    use({
      'MunifTanjim/nvim-treesitter-lua',
      config = function()
        require('nvim-treesitter-lua').setup()
      end,
    })

    -- coc.nvim provides rename and highlight current symbol
    use({ 'nvim-treesitter/nvim-treesitter-refactor' })
    -- }}}

    -- lsp client
    use({
      'neoclide/coc.nvim',
      branch = 'release',
      config = require('plugins.coc-nvim').init,
    })

    -- {{{2 search
    use({ 'ibhagwan/fzf-lua', requires = { 'nvim-web-devicons' } })
    -- {{{3 telescope related
    use({
      'nvim-telescope/telescope.nvim',
      requires = { 'plenary.nvim' },
      config = require('plugins.telescope').init,
    })
    use({
      'nvim-telescope/telescope-ui-select.nvim',
      config = function()
        require('telescope').load_extension('ui-select')
      end,
    })
    use({
      'nvim-telescope/telescope-fzf-native.nvim',
      run = 'make',
      after = 'telescope.nvim',
      config = function()
        require('telescope').load_extension('fzf')
      end,
    })
    use({
      'TC72/telescope-tele-tabby.nvim',
      after = 'telescope.nvim',
      config = function()
        require('telescope').load_extension('tele_tabby')
      end,
    })
    use({
      'camgraff/telescope-tmux.nvim',
      after = 'telescope.nvim',
      requires = 'nvim-terminal.lua',
      config = function()
        require('telescope').load_extension('tmux')
      end,
    })
    use({
      'nvim-telescope/telescope-project.nvim',
      after = 'telescope.nvim',
    })
    use({
      'sudormrfbin/cheatsheet.nvim',
      config = require('plugins.cheatsheet').init,
    })
    use({
      'AckslD/nvim-neoclip.lua',
      requires = { 'sqlite.lua' },
      after = 'telescope.nvim',
      config = require('plugins.neoclip').init,
    })
    use({
      'nvim-telescope/telescope-frecency.nvim',
      config = function()
        require('telescope').load_extension('frecency')
      end,
      requires = { 'sqlite.lua' },
    })
    use({
      'Shatur/neovim-session-manager',
      config = require('plugins.session-manager').init,
      requires = { 'telescope.nvim', 'plenary.nvim' },
    })
    use({
      'fannheyward/telescope-coc.nvim',
      after = 'telescope.nvim',
      config = function()
        require('telescope').load_extension('coc')
      end,
    })
    -- {{{2 others
    use({
      'glacambre/firenvim',
      run = function()
        vim.fn['firenvim#install'](0)
      end,
      config = require('plugins.firenvim').init,
    })
    -- auto detect indent type and size
    use({
      'nmac427/guess-indent.nvim',
      config = function()
        require('guess-indent').setup({})
      end,
    })
    use({ -- enhance terminal UX
      'akinsho/toggleterm.nvim',
      tag = '*',
      config = require('plugins.toggleterm').init,
    })
    -- https://github.com/neovim/neovim/issues/12587
    use('antoinemadec/FixCursorHold.nvim') -- TODO(remove this): temporarily fix CursorHold not triggerred
  end,
  config = {
    compile_path = vim.fn.stdpath('config') .. '/lua/packer_compiled.lua',
    display = {
      open_fn = require('packer.util').float,
    },
  },
})
-- vim: set fdm=marker:
