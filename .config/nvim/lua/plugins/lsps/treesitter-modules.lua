local M = {
  'MeanderingProgrammer/treesitter-modules.nvim',
  dependencies = { 'nvim-treesitter/nvim-treesitter' },
  ---@module 'treesitter-modules'
  ---@type ts.mod.UserConfig
  opts = {
    fold = { enable = true },
    highlight = { enable = true },
    indent = { enable = true },
    incremental_selection = { enable = true },
  },
}
return {}
