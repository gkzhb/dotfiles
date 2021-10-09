local M = {}

function M.init()
  -- load local lua module '~/.config/nvim/lua/local-projects.lua' as plugin 'project_config' value
  local localProjectConfigPath = vim.fn.stdpath('config') .. '/local-projects.lua'
  local projectConfig = {
    { -- neovim config
      path = vim.fn.expand(vim.fn.stdpath('config')),
      config = require('projects.nvim-config').init
    }
  }
  if vim.fn.empty(vim.fn.glob(localProjectConfigPath)) == 0 then
    local localProjectConfig = require('local-projects')
    -- merge localProjectConfig into projectConfig
    localProjectConfig = table.move(localProjectConfig, 1, #localProjectConfig, #projectConfig + 1, projectConfig)
  end
  require('nvim-projectconfig').load_project_config({
    project_config = projectConfig,
  })
end

return M
