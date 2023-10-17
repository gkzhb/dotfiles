local M = {}

--- Check whether a module exists
--- @param name string module name
--- @return boolean boolean
-- from https://stackoverflow.com/questions/15429236/how-to-check-if-a-module-exists-in-lua
function M.isModuleAvailable(name)
  if package.loaded[name] then
    return true
  else
    for _, searcher in ipairs(package.searchers or package.loaders) do
      local loader = searcher(name)
      if type(loader) == 'function' then
        package.preload[name] = loader
        return true
      end
    end
    return false
  end
end

--- Inspect lua objects
-- from https://github.com/nanotee/nvim-lua-guide#tips-3
function M.debugPrint(...)
  local objects = {}
  for i = 1, select('#', ...) do
    local v = select(i, ...)
    table.insert(objects, vim.inspect(v))
  end
  print(table.concat(objects, '\n'))
  return ...
end

_G.debugPrint = M.debugPrint

--- @deprecated use which-key instead
--- Add key mapping
function M.map(type, key, value, opts)
  vim.api.nvim_set_keymap(type, key, value, vim.tbl_extend('keep', opts or {}, { noremap = true, silent = true }))
end

function M.esc(cmd)
  return vim.api.nvim_replace_termcodes(cmd, true, false, true)
end

function M.t(cmd)
  return vim.api.nvim_replace_termcodes(cmd, true, true, true)
end

--- Load local lua config file in 'lua/local/' directory
--- @param filename string filenamne without '.lua' extension
--- @return any any exported module or false
function M.loadLocal(filename)
  local mod = 'local.' .. filename
  if M.isModuleAvailable(mod) then
    return M.loadModuleSafely(mod)
  end
  return false
end

--- Call function without throwing errors except that func param
--- is not function
--- @param func function function to call
--- @param ... any function parameters
--- @throws {string} 'func' is not a function
function M.callFunctionSafely(func, ...)
  if type(func) ~= 'function' then
    error('func should be a function', 2)
  end
  local m, result = pcall(func, ...)
  if m then
    return result
  else
    print(result)
    vim.api.nvim_echo(result, true, {})
    return false
  end
end

--- Load lua module without throwing errors but print errors
--- @param mod string module name
function M.loadModuleSafely(mod)
  return M.callFunctionSafely(require, mod)
end

return M
