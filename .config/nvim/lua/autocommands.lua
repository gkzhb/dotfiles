-- terminal optimize from
-- https://www.reddit.com/r/neovim/comments/ohdptb/how_do_you_switch_terminal_buffers_but_keep_the/
-- https://github.com/akinsho/toggleterm.nvim/tree/main
function _G.set_terminal_keymaps()
  local opts = { noremap = true, silent = true }
  vim.api.nvim_buf_set_keymap(0, 'n', '<CR>', 'i', opts)
end

vim.cmd('autocmd! TermOpen term://* lua set_terminal_keymaps()')
vim.cmd([[
  augroup TerminalBehavior
    autocmd!
    autocmd TermOpen * startinsert
    autocmd WinEnter term://* startinsert
  augroup END
]])
