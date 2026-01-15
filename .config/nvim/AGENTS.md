# AGENTS.md - Neovim Lua Configuration

This neovim config uses lazy.nvim plugin manager, which-key.nvim.

## Build/Lint/Test Commands
- **Format code**: `stylua .` (formats all Lua files)
- **Install plugins**: `:Lazy install` (in Neovim)
- **Update plugins**: `:Lazy update` (in Neovim)
- **Clean plugins**: `:Lazy clean` (in Neovim)
- **Plugin manager**: `:Lazy` (open lazy.nvim UI)
- **No formal test framework** - manual testing only

## Code Style Guidelines
- **Language**: Lua for Neovim configuration
- **Formatter**: StyLua (2 spaces, single quotes, Unix line endings)
- **File naming**: snake_case (e.g., `basic-setup.lua`)
- **Function naming**: camelCase
- **Module structure**: Use `local M = {}` pattern, return `M`
- **Error handling**: Use `utils.loadModuleSafely()` for optional modules
- **Code folding**: Use fold markers `{{{1`, `{{{2`, `}}}`
- **Comments**: Use `--` for single line, `--[[ ]]` for multi-line
- **Imports**: Use `require('module')` with single quotes
- **Local config**: Place machine-specific code in `lua/local/customize.lua`

## Key Patterns
- Check for VSCode Neovim: `if vim.g.vscode then`
- Safe module loading: `utils.loadModuleSafely('module-name')`
- Use hooks: `beforeAll`, `afterAll` in local config
- Plugin configs in `lua/plugins/` directory

## Plugin Configuration Standards
- **Key mappings**: Use `M.keys` table in plugin config instead of separate `mappings()` function
    - For example
    ```lua
    local M = {
        ... -- plugin definitions
    }
    ...
    M.keys = {
        ... -- mapping configs
    }
    ```
    - Use the above example config format especially for complex mapping configs.
- **Plugin structure**: Return plugin config table with `keys`, `config`, `dependencies` fields
- **Key mapping format**: Use `{ '<key>', '<command>', desc = 'description', mode = 'n' }` syntax
- **Grouping keys**: Use `{ '<leader>x', group = 'group name' }` for key groups
- **Migration pattern**: Remove `M.mappings()` functions and `require('plugin').mappings()` calls
- **Centralized mappings**: Keep all plugin-related keymaps in their respective plugin config files
