local M = {
  'goolord/alpha-nvim',
  dependencies = { 'kyazdani42/nvim-web-devicons' },
}

function M.config()
  require('alpha').setup(require('alpha.themes.startify').opts)
end

return M
