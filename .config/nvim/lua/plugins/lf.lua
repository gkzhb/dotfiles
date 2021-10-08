local M = {}
function M.setup()
  vim.g.lf_map_keys = 0
  vim.g.lf_replace_netrw = 1 -- Open lf when vim opens a directory
end
return M
