-- {{{1 pckr managed plugins
local cfg = _G.getLocalConfig()
require('pckr').add({
  -- {{{2 dependencies
  'kyazdani42/nvim-web-devicons',
  'nvim-lua/plenary.nvim',
  'tami5/sqlite.lua',
  { -- hightlight terminal colors
    'norcalli/nvim-terminal.lua',
    config = function()
      require('terminal').setup()
    end,
  },
  -- {{{2 performance
  'dstein64/vim-startuptime',
  -- {{{2 color theme
  {
    'Mofiqul/vscode.nvim',
    config = require('plugins.vscode').init
  },
  -- {{{2 display enhancement
  -- if not _G.getLocalConfig().performantMode then
  --   ({
  --     'karb94/neoscroll.nvim',
  --     config = require('plugins.neoscroll').init,
  --   })
  -- end
  {
    'mrjones2014/legendary.nvim',
    config = require('plugins.legendary').init,
  },
  {
    'folke/which-key.nvim',
    config_pre = require('plugins.which-key').setup,
    config = require('plugins.which-key').init,
    requires = { 'legendary.nvim' },
  },
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
  -- greeter
  {
    'goolord/alpha-nvim',
    requires = { 'kyazdani42/nvim-web-devicons' },
    config = require('plugins.alpha-greeter').init,
  },
  {
    'lukas-reineke/indent-blankline.nvim',
    requires = 'Mofiqul/vscode.nvim',
    config = require('plugins.indent-blankline').init,
  },
  -- beautify notifications
  {
    'rcarriga/nvim-notify',
    config = require('plugins.notify').init,
  },
  -- show colors
  -- {
  --   'norcalli/nvim-colorizer.lua',
  --   config = require('plugins.colorizer').init,
  -- },
  -- set foldtext
  -- {
  --   'scr1pt0r/crease.vim',
  --   config = require('plugins.crease').init,
  -- },
  {
    'luukvbaal/statuscol.nvim', -- linenumber, line sign, etc
    config = function()
      local builtin = require('statuscol.builtin')
      require('statuscol').setup({
        relculright = true,
        segments = {
          {
            text = { '%s' },
            click = 'v:lua.ScSa',
            sign = { name = { '.*' }, maxwidth = 3 }
          },
          { text = { builtin.lnumfunc, ' ' }, click = 'v:lua.ScLa' },
          { text = { builtin.foldfunc, ' ' }, click = 'v:lua.ScFa' },
        },
      })
    end,
  },
  {
    'kevinhwang91/nvim-ufo', -- foldtext
    requires = { 'kevinhwang91/promise-async', 'luukvbaal/statuscol.nvim', 'folke/which-key.nvim' },
    config = require('plugins.ufo').init,
  },
  -- vim mark enhancement
  {
    'chentoast/marks.nvim',
    config = require('plugins.marks').init
  },
  -- status line and tab line
  {
    'akinsho/bufferline.nvim',
    branch = 'main',
    config = require('plugins.bufferline').init,
    requires = { 'Mofiqul/vscode.nvim' },
  },
  -- improve bufferline.nvim, separate buffers to tabpages
  {
    'tiagovla/scope.nvim',
    config = function()
      require('scope').setup()
    end,
  },
  {
    'windwp/windline.nvim',
    config = require('plugins.windline').init,
    requires = 'Mofiqul/vscode.nvim',
  },
  --  {
  --   'rebelot/heirline.nvim',
  --   config = require('plugins.heirline').init
  -- }
  -- file explorer
  {
'mikavilpas/yazi.nvim',
    config = function()
      vim.g.loaded_netrwPlugin = 1
    end
  },
  -- { -- used for lf
  --   'is0n/fm-nvim',
  --   config = require('plugins.fm-nvim').init,
  -- },
  {
    'kyazdani42/nvim-tree.lua',
    config = function()
      require('nvim-tree').setup({})
    end,
  },
  {
    'p00f/nvim-ts-rainbow',
    requires = 'nvim-treesitter/nvim-treesitter'
  },
  -- pretty list
  {
    'folke/trouble.nvim',
    requires = 'kyazdani42/nvim-web-devicons',
    config = require('plugins.trouble').init,
  },
  {
    'https://gitlab.com/yorickpeterse/nvim-pqf.git',
    config = require('plugins.pqf').init,
  },
  {
    'mbbill/undotree',
    cmd = { 'UndotreeToggle' },
  },
  -- {{{2 movement
  -- {
  --   't9md/vim-choosewin',
  --   config = require('plugins.choosewin').init,
  -- },
  -- {
  --   'dstein64/vim-win',
  --   config = require('plugins.vim-win').init,
  -- },
  {
    'ggandor/leap.nvim',
    config = function()
      require('leap').set_default_mappings()
    end,
  },
  'szw/vim-maximizer',
  'tpope/vim-unimpaired', -- `[<char>`, `]<char>` related keymappings
  {
    'numToStr/Navigator.nvim',
    config = function()
      require('Navigator').setup()
      vim.keymap.set({ 'n', 't' }, '<C-h>', '<CMD>NavigatorLeft<CR>')
      vim.keymap.set({ 'n', 't' }, '<C-l>', '<CMD>NavigatorRight<CR>')
      vim.keymap.set({ 'n', 't' }, '<C-k>', '<CMD>NavigatorUp<CR>')
      vim.keymap.set({ 'n', 't' }, '<C-j>', '<CMD>NavigatorDown<CR>')
    end
  },
  -- {{{2 edit
  'tpope/vim-surround',
  {
    'windwp/nvim-projectconfig',
    config = require('plugins.projectconfig').init,
    requires = { 'coc.nvim' },
  },
  {
    'lambdalisue/suda.vim',
    config_pre = require('plugins.suda').setup,
  },
  'tpope/vim-repeat',
  {
    'windwp/nvim-ts-autotag',
    requires = { 'nvim-treesitter/nvim-treesitter' },
  },
  'tpope/vim-commentary',
  'honza/vim-snippets', -- coc-snippets needs snippets
  {
    -- generate documentation comment for class, function, type
    'danymat/neogen',
    config = function()
      require('neogen').setup({})
    end,
    requires = { 'nvim-treesitter/nvim-treesitter' },
  },
  { -- convert string between different naming cases
    'johmsalas/text-case.nvim',
    config = function()
      require('textcase').setup({})
    end,
  },
  { -- enhanced vim word motion (support to distinguish words in camel case string)
    'chaoren/vim-wordmotion',
    config_pre = function()
      -- do not replace default vim word motions, add prefix 'X' instead
      vim.g.wordmotion_prefix = 'X'
    end,
  },
  -- {{{2 git related
  {
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
  },
  {
    'rbong/vim-flog', -- git branch graph view
    cmd = { 'Flog', 'Flogsplit' },
    requires = { 'vim-fugitive' },
  },
  -- two below are not working
  --  'junegunn/gv.vim' -- git commit browser
  --  'sodapopcan/vim-twiggy' -- git branch push/pull/rebase
  -- {{{3 treesitter
  {
    'nvim-treesitter/nvim-treesitter',
    run = cfg.performantMode and ':TSUpdateSync' or ':TSUpdate',
    config = require('plugins.nvim-treesitter').init,
  },
  {
    'nvim-treesitter/nvim-treesitter-textobjects',
    requires = 'nvim-treesitter/nvim-treesitter',
  },
  {
    'JoosepAlviste/nvim-ts-context-commentstring',
    requires = 'nvim-treesitter/nvim-treesitter',
    event = 'BufRead',
    config_pre = function()
      vim.g.skip_ts_context_commentstring_module = true
    end,
  },
  {
    'nvim-treesitter/playground',
    requires = 'nvim-treesitter/nvim-treesitter',
  },
  -- do not support matchparen highlight paried
  -- ({ 'theHamsta/nvim-treesitter-pairs' })
  -- incompatible with the lua treesitter parser
  {
    'andymass/vim-matchup',
    requires = 'nvim-treesitter/nvim-treesitter',
    config = require('plugins.matchup').init,
  }, -- support tree-sitter
  --  { -- get errors in this plugin
  --   'romgrk/nvim-treesitter-context',
  --   config = function() require('treesitter-context').setup({}) end
  -- }

  -- auto pair while coding
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

  -- coc.nvim provides rename and highlight current symbol
  { 'nvim-treesitter/nvim-treesitter-refactor', requires = 'nvim-treesitter/nvim-treesitter' },
  -- }}}
  -- lsp client
  {
    'neoclide/coc.nvim',
    branch = 'release',
    config = require('plugins.coc-nvim').init,
  },
  { -- code snippets
    'mlaursen/vim-react-snippets',
  },
  -- {{{2 search
  {
    'ibhagwan/fzf-lua',
    requires = { 'kyazdani42/nvim-web-devicons' },
    config = require('plugins.fzf').init,
  },
  {
    'nvim-pack/nvim-spectre',
    requires = { 'nvim-lua/plenary.nvim' },
    config = require('plugins.spectre').init,
  },
  -- {{{3 telescope related
  {
    'nvim-telescope/telescope.nvim',
    requires = { 'nvim-lua/plenary.nvim' },
    config = require('plugins.telescope').init,
  },
  {
    'nvim-telescope/telescope-ui-select.nvim',
    requires = { 'nvim-telescope/telescope.nvim' },
    config = function()
      require('telescope').load_extension('ui-select')
    end,
  },
  {
    'nvim-telescope/telescope-fzf-native.nvim',
    run = 'make',
    requires = { 'nvim-telescope/telescope.nvim' },
    config = function()
      require('telescope').load_extension('fzf')
    end,
  },
  {
    'TC72/telescope-tele-tabby.nvim',
    requires = { 'nvim-telescope/telescope.nvim' },
    config = function()
      require('telescope').load_extension('tele_tabby')
    end,
  },
  {
    'camgraff/telescope-tmux.nvim',
    requires = { 'nvim-telescope/telescope.nvim', 'norcalli/nvim-terminal.lua' },
    config = function()
      require('telescope').load_extension('tmux')
    end,
  },
  {
    'nvim-telescope/telescope-project.nvim',
    requires = { 'nvim-telescope/telescope.nvim' },
  },
  {
    'sudormrfbin/cheatsheet.nvim',
    requires = { 'nvim-telescope/telescope.nvim' },
    config = require('plugins.cheatsheet').init,
  },
  {
    'AckslD/nvim-neoclip.lua',
    requires = { 'nvim-telescope/telescope.nvim', 'tami5/sqlite.lua' },
    config = require('plugins.neoclip').init,
  },
  -- {
  --   'nvim-telescope/telescope-frecency.nvim',
  --   config = function()
  --     require('telescope').load_extension('frecency')
  --   end,
  --   requires = { 'nvim-telescope/telescope.nvim' },
  -- },
  {
    'Shatur/neovim-session-manager',
    config = require('plugins.session-manager').init,
    requires = { 'nvim-telescope/telescope.nvim', 'nvim-lua/plenary.nvim' },
  },
  {
    'fannheyward/telescope-coc.nvim',
    requires = { 'nvim-telescope/telescope.nvim' },
    config = function()
      require('telescope').load_extension('coc')
    end,
  },
  -- {{{2 others
  {
    'glacambre/firenvim',
    run = function()
      vim.fn['firenvim#install'](0)
    end,
    config = require('plugins.firenvim').init,
  },
  -- auto detect indent type and size
  {
    'nmac427/guess-indent.nvim',
    config = function()
      require('guess-indent').setup({})
    end,
  },
  { -- enhance terminal UX
    'akinsho/toggleterm.nvim',
    -- tag = "*",
    config = require('plugins.toggleterm').init,
  },
  -- { -- run lua code
  --   'bfredl/nvim-luadev',
  -- }
})
-- vim: set fdm=marker:
