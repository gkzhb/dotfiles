local M = {}

function M.map(type, key, value, opts)
  vim.api.nvim_set_keymap(
    type,
    key,
    value,
    vim.tbl_extend(
      'keep',
      opts or {},
      { noremap = true, silent = true }
    )
  )
end

function M.esc(cmd)
  return vim.api.nvim_replace_termcodes(cmd, true, false, true)
end

return M
