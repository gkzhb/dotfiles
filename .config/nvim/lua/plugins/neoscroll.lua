local M = {}

function _G.NeoscrollEnablePerformantMode()
  vim.b.neoscroll_performance_mode = true
end

function M.init()
  require('neoscroll').setup({
    mappings = {'<C-u>', '<C-d>', '<C-b>', '<C-f>',
      '<C-y>', '<C-e>', 'zt', 'zz', 'zb'},
    easing_function = nil
  })

  -- Syntax: t[keys] = {function, {function arguments}}
  local t = {
    -- Use the "sine" easing function
    ['<C-u>'] = {'scroll', {'-vim.wo.scroll', 'true', '350', [['sine']]}},
    ['<C-d>'] = {'scroll', { 'vim.wo.scroll', 'true', '350', [['sine']]}},
    -- Use the "circular" easing function
    ['<C-b>'] = {'scroll', {'-vim.api.nvim_win_get_height(0)', 'true', '500', [['circular']]}},
    ['<C-f>'] = {'scroll', { 'vim.api.nvim_win_get_height(0)', 'true', '500', [['circular']]}},
    -- Pass "nil" to disable the easing animation (constant scrolling speed)
    ['<C-y>'] = {'scroll', {'-0.10', 'false', '100', nil}},
    ['<C-e>'] = {'scroll', { '0.10', 'false', '100', nil}},
    -- When no easing function is provided the default easing function (in this case "quadratic") will be used
    ['zt']    = {'zt', {'300'}},
    ['zz']    = {'zz', {'300'}},
    ['zb']    = {'zb', {'300'}},
  }
  

  if _G.getLocalConfig().performantMode then
    vim.cmd([[
      autocmd BufEnter * lua NeoscrollEnablePerformantMode()
    ]])
  else 
    require('neoscroll.config').set_mappings(t)
  end
end

return M
