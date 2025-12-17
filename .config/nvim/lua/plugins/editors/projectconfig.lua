-- 项目配置
local M = {
  'windwp/nvim-projectconfig',
  dependencies = { 'neoclide/coc.nvim' },
}

function M.config()
  -- load local lua module '~/.config/nvim/lua/local/local-projects.lua' as plugin 'project_config' value
  local localProjectConfig = require('utils').loadLocal('local-projects')
  local projectConfig = {
    { -- neovim config
      path = vim.fn.expand(vim.fn.stdpath('config')),
      config = require('projects.nvim-config').init,
    },
  }
  if localProjectConfig then
    -- merge localProjectConfig into projectConfig
    localProjectConfig =
      table.move(localProjectConfig.config, 1, #localProjectConfig.config, #projectConfig + 1, projectConfig)
  end
  require('nvim-projectconfig').load_project_config({
    project_config = projectConfig,
  })
end

return M
