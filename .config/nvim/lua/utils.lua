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

--- Load local lua config file
--- @param filename string filenamne without '.lua' extension
--- @return nil or exported module from the file
function M.loadLocal(filename)
  local filePath = vim.fn.stdpath('config') .. '/lua/local/' .. filename .. '.lua'
  if vim.fn.empty(vim.fn.glob(filePath)) == 0 then
    return require('local.' .. filename)
  end
  return nil
end

return M
