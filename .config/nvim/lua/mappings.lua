local M = {}
local utils = require('utils')
local map = utils.map

function SetTab (size)
  vim.opt.tabstop = size
  vim.opt.softtabstop = size
  vim.opt.shiftwidth = size
end

function M.init()
  -- leader key
  vim.g.mapleader=' '
  vim.g.maplocalleader=' '
  vim.opt.ttimeout=true
  vim.opt.tm=500
end

function M.setMappings()
  -- which key plugin
  map('n', '<leader>', ':WhichKey "<Space>"<CR>')

  -- fugitive
  map('n', '<leader>g', ':G<CR>')
  map('n', '<leader>g<Space>', ':G<Space>', { silent = false })

  -- choosewin
  map('n', '-', '<Plug>(choosewin)', { noremap = false, silent = true })

  -- lf
  map('n', '<leader>lf', ':Lf<CR>')

  -- maximizer
  map('n', '<leader>z', ':MaximizerToggle<CR>')

  -- tab actions
  map('n', '<leader>t', '<cmd>TablineTabNew<CR>')
  map('n', '<leader>tr', '<cmd>TablineTabRename ')
  -- tabline.nvim
  -- map('n', 'gt', '<cmd>TablineBufferNext<CR>')
  -- map('n', 'gT', '<cmd>TablineBufferPrevious<CR>')
  -- quick actions
  map('n', '<leader>w', ':w<CR>')
  map('n', '<leader>q', ':q<CR>')
  map('n', '<leader>cp', ':set invpaste<CR>')
  map('n', '<leader>ci', ':set list!<CR>')
  map('n', '<leader>ch', ':noh<CR>')

  map('n', '<C-N>', ':bnext<CR>')
  map('n', '<C-P>', ':bprev<CR>')


  map('n', '<leader>ct4', ':call v:lua.SetTab(4)<CR>')
  map('n', '<leader>ct2', ':call v:lua.SetTab(2)<CR>')
  -- project actions
  map('n', '<leader>pc', '<cmd>lua require("nvim-projectconfig").edit_project_config()<CR>')

  -- coc.nvim
  -- local coc = require('plugins.coc-nvim')
  map('i', '<TAB>', 'v:lua.CocTab()', { expr = true, silent = false, nowait = true })
  map('i', '<S-TAB>', 'v:lua.CocSTab()', { expr = true })
  map('i', '<CR>', 'v:lua.CocEnterConfirm()', { expr = true, nowait = true })
  -- vim.cmd([[
  --   inoremap <silent><expr> <cr> pumvisible() ? coc#_select_confirm()
  --     \: "\<C-g>u\<CR>\<c-r>=coc#on_enter()\<CR>"
  -- ]])


  -- Use `[g` and `]g` to navigate diagnostics
  -- Use `:CocDiagnostics` to get all diagnostics of current buffer in location list.
  local noNoremap = { noremap = false }
  map('n', '[g', '<Plug>(coc-diagnostic-prev)', noNoremap)
  map('n', ']g', '<Plug>(coc-diagnostic-next)', noNoremap)

  -- GoTo code navigation.
  map('n', 'gd', '<Plug>(coc-definition)', noNoremap)
  map('n', 'gy', '<Plug>(coc-type-definition)', noNoremap)
  map('n', 'gi', '<Plug>(coc-implementation)', noNoremap)
  map('n', 'gr', '<Plug>(coc-references)', noNoremap)
  -- Use K to show documentation in preview window.
  map('n', 'K', ':call v:lua.CocShowDocumentation()<CR>')
  -- TODO: show documentation
  -- Highlight the symbol and its references when holding the cursor.
  vim.cmd([[
    autocmd CursorHold * silent call CocActionAsync('highlight')
  ]])
  -- Symbol renaming.
  map('n', '<leader>rn', '<Plug>(coc-rename)', noNoremap)
  -- Formatting selected code.
  map('n', '<leader>f', '<Plug>(coc-format-selected)', noNoremap)
  map('x', '<leader>f', '<Plug>(coc-format-selected)', noNoremap)
  map('v', '<leader>f', '<Plug>(coc-format-selected)', noNoremap)
  -- Applying codeAction to the selected region.
  -- Example: `<leader>aap` for current paragraph
  map('x', '<leader>a', '<Plug>(coc-codeaction-selected)', noNoremap)
  map('n', '<leader>a', '<Plug>(coc-codeaction-selected)', noNoremap)

  -- Remap keys for applying codeAction to the current buffer.
  map('n', '<leader>ac', '<Plug>(coc-codeaction)', noNoremap)
  -- Apply AutoFix to problem on the current line.
  map('n', '<leader>qf', '<Plug>(coc-fix-current)', noNoremap)

  -- Map function and class text objects
  -- NOTE: Requires 'textDocument.documentSymbol' support from the language server.
  map('x', 'if', '<Plug>(coc-funcobj-i)', noNoremap)
  map('o', 'if', '<Plug>(coc-funcobj-i)', noNoremap)
  map('x', 'af', '<Plug>(coc-funcobj-a)', noNoremap)
  map('o', 'af', '<Plug>(coc-funcobj-a)', noNoremap)
  map('x', 'ic', '<Plug>(coc-classobj-i)', noNoremap)
  map('o', 'ic', '<Plug>(coc-classobj-i)', noNoremap)
  map('x', 'ac', '<Plug>(coc-classobj-a)', noNoremap)
  map('o', 'ac', '<Plug>(coc-classobj-a)', noNoremap)

  -- scroll float window
  map('n', '<C-f>', 'coc#float#has_scroll() ? coc#float#scroll(1) : "<C-f>"', { nowait = true, expr = true })
  map('n', '<C-b>', 'coc#float#has_scroll() ? coc#float#scroll(0) : "<C-b>"', { nowait = true, expr = true })
  map('i', '<C-f>', 'coc#float#has_scroll() ? "<c-r>=coc#float#scroll(1)<cr>" : "<Right>"', { nowait = true, expr = true })
  map('i', '<C-b>', 'coc#float#has_scroll() ? "<c-r>=coc#float#scroll(0)<cr>" : "<Left>"', { nowait = true, expr = true })

  -- coc explorer
  map('n', '<leader>e', ':call CocAction("runCommand", "explorer", "--preset", "workspace", getcwd())<CR>')
  -- coc lists
  map('n', '<leader>l', ':<C-u>CocList <CR>')
  map('n', '<leader>y', ':<C-u>CocList -A --normal yank<cr>')
  map('n', '<leader>lb', ':<C-u>CocList buffers<CR>')
  map('n', '<leader>ls', ':<C-u>CocList files<CR>')
  map('n', '<leader>lg', ':<C-u>CocList grep<CR>')
  map('n', '<leader>b', ':<C-u>CocList --normal buffers<CR>')

  -- telescope
  map('n', '<leader>ff', '<cmd>lua require("telescope.builtin").find_files()<cr>')
  map('n', '<leader>fg', '<cmd>lua require("telescope.builtin").live_grep()<cr>')
  map('n', '<leader>fb', '<cmd>lua require("telescope.builtin").buffers()<cr>')
  map('n', '<leader>fh', '<cmd>lua require("telescope.builtin").help_tags()<cr>')
end
return M
