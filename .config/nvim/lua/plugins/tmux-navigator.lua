local M = {}
function M.init()
  -- Disable tmux navigator when zooming the Vim pane
  vim.g.tmux_navigator_disable_when_zoomed = 1
end
return M
