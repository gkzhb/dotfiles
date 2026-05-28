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

function _G.fugitive_commit_foldexpr(lnum)
  local line = vim.fn.getline(lnum)
  local prev = lnum > 1 and vim.fn.getline(lnum - 1) or ''

  local is_header = line:match('^tree ') or line:match('^parent ') or line:match('^author ') or line:match('^committer ')
  local is_header_continuation = prev:match('^gpgsig ') or prev:match('^ ') or line:match('^gpgsig ') or line:match('^ ')
  local is_diff = line:match('^diff %-%-git ')

  if line == '' then
    return '0'
  end

  if is_diff then
    return '>1'
  end

  if is_header or is_header_continuation then
    if prev == '' then
      return '>1'
    end
    return '1'
  end

  if prev == '' then
    return '>1'
  end

  return '1'
end

vim.api.nvim_create_autocmd('BufWinEnter', {
  pattern = 'fugitive://*',
  callback = function(args)
    vim.schedule(function()
      if not vim.api.nvim_buf_is_valid(args.buf) then
        return
      end

      local fugitive_type = vim.b[args.buf].fugitive_type
      if fugitive_type == 'commit' then
        vim.wo.foldmethod = 'expr'
        vim.wo.foldexpr = 'v:lua.fugitive_commit_foldexpr(v:lnum)'
      elseif fugitive_type == 'tag' or fugitive_type == 'tree' or fugitive_type == 'blob' then
        vim.wo.foldmethod = 'syntax'
        vim.wo.foldexpr = '0'
      end
    end)
  end,
})

-- file type
vim.cmd([[
  autocmd BufNewFile,BufRead *.mdx :set filetype=markdown
]])
