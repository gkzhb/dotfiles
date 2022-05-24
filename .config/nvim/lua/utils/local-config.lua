local M = {
  hooks = nil,
}
M.HookNames = {
  --- Before any plugin loads and any local config loads
  beforeAll = 'beforeAll',
  --- After all plugins load and configs load
  afterAll = 'afterAll',
}
local utils = require('utils')

--- Initialize local config options
function M.initLocalConfig()
  -- local config options
  _G.localConfig = {
    performantMode = false, -- be enabled on low performance CPU
  }
end

--- Update local config options
--
--- @throws {string} parameter should be a table
function M.updateLocalConfig(newConfig)
  if type(newConfig) ~= 'table' then
    error('parameter "newConfig" should be a table', 2)
  end
  for k, v in pairs(newConfig) do
    _G.localConfig[k] = v
  end
end

--- Get local config options
function M.getLocalConfig()
  return _G.localConfig
end

_G.getLocalConfig = M.getLocalConfig

--- Read hooks from local config code 'lua/local/customize.lua'
--
--- @printError {string} no module exported from 'customize.lua'
function M.loadHooks()
  local custObj = utils.loadLocal('customize') -- local config code
  if type(custObj) ~= 'table' and custObj ~= false then
    print('Invalid customize.lua config file, should export a module')
  end
  M.hooks = custObj
end

--- Call hooks
--- @param name string name in HookNames
--- @printError {string} hooks should be functions
function M.runHook(name)
  if type(M.hooks) == 'table' and M.hooks[name] then
    if type(M.hooks[name]) ~= 'function' then
      print('hook "' .. name .. '" should be a function')
    else
      M.hooks[name]()
    end
  end
end

return M
