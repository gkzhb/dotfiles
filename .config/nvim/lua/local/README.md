# Local Configurations

This directory stores config files that are unique on each machine. Therefore,
they are not added to git repository.

## Examples

`utils.local-config` module provides `HookNames` which stores all the names of
hook functions that will be invoked in the root `init.lua` configuration file.

You need to export a module with these hook functions in `customize.lua` file.

For example,

```lua customize.lua
local M = {}
local hooks = require('utils.local-config').HookNames

M[hooks.beforeAll] = function ()
  require('utils.local-config').updateLocalConfig({
    performantMode = true,
  })
end

M[hooks.afterAll] = function ()
  local wk = require('which-key')
  vim.fn['coc#config']('rust-analyzer', {
    ['server.path'] = '/usr/bin/rust-analyzer'
  })
end

return M
```

The above lua file exports a module with two hook functions. `beforeAll` hook
will be invoked before any configurations executes, while `afterAll` hook will
be invoked at the end of root `init.lua`.
