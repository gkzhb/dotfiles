-- Download this file and run `nvim -u /path/to/this/lua/file`
-- Reference: https://github.com/ibhagwan/fzf-lua/blob/main/minimal_init.lua
local packer_is_optional = false

if vim.api.nvim_call_function('has', {'nvim-0.5'}) ~= 1 then
  vim.api.nvim_command('echohl WarningMsg | echom "neovim > v0.5 is required | echohl None"')
  return
end

local res, packer = pcall(require, "packer")
local install_suffix = "/site/pack/packer/%s/packer.nvim"
local install_path = vim.fn.stdpath("data") .. string.format(install_suffix, packer_is_optional and "opt" or "start")
local is_installed = vim.loop.fs_stat(install_path) ~= nil

if not res and is_installed then
  vim.cmd("packadd packer.nvim")
  res, packer = pcall(require, "packer")
end

if not res then
  print("Downloading packer.nvim...\n")
  vim.fn.system({
    "git", "clone", '--depth', '1',
    "https://github.com/wbthomason/packer.nvim",
    install_path,
  })
  vim.cmd("packadd packer.nvim")
  res, packer = pcall(require, "packer")
  if res then
    vim.fn.delete(packer.config.compile_path, "rf")
    print("Successfully installed packer.nvim.")
  else
    print(("Error installing packer.nvim\nPath: %s"):format(install_path))
    return
  end
end

packer.startup({
  function(use)
    use { 'wbthomason/packer.nvim', opt = packer_is_optional }
    use 'ggandor/lightspeed.nvim'
  end,
  -- do not remove installed plugins (when running 'vim -u')
  config = { auto_clean = false, compile_path = vim.fn.stdpath('config') .. '/lua/mini_config_compiled.lua' }
})

packer.on_compile_done = function()
  packer.loader('lightspeed.nvim')
end

if not vim.loop.fs_stat(packer.config.compile_path) then
  packer.sync()
else
  packer.compile()
end
