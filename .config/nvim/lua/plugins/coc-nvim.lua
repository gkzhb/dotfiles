local M = {}
local utils = require('utils')

function M.init()
  -- {{{2 coc.vim config
  -- {{{3 coc-settings.json
  -- help: coc#config()
  vim.fn['coc#config']('coc', {
    preferences = {
      colorSupport = false, -- coc-highlight
    },
  })
  -- {{{4 coc browser
  vim.fn['coc#config']('browser', {
    port = 8990,
  })
  -- {{{4 coc explorer
  vim.fn['coc#config']('explorer', {
    ['buffer.root.template'] = '[icon & 1] BUFFERS',
    ['file.root.template'] = '[icon & 1] PROJECT ([root]) [fullpath]',
    ['file.child.template'] = '[git | 2] [selection | clip | 1] [indent][icon | 1] [diagnosticError & 1][filename omitCenter 1][modified][readonly] [linkIcon & 1][link growRight 1 omitCenter 5]',
    ['file.showHiddenFiles'] = true,
    ['file.auto'] = false,
    ['icon.enableVimDevicons'] = false,
    ['icon.enableNerdfont'] = false,
    ['previewAction.onHover'] = 'labeling',
    ['keyMappings.global'] = {
      v = 'open:vsplit',
      ['<cr>'] = {'wait', 'expandable?', 'expanded?', 'collapse', 'expand', 'open'},
      cd = {'cd'},
      m = 'actionMenu',
      mc = 'copyFile',
      C = 'copyFile',
      md = 'delete',
      D = 'delete',
      H = {'wait', 'gotoParent'},
      L = {'cd'}
      }
    })
  -- {{{4 coc lists
  vim.fn['coc#config']('list.source.grep.args', {'--hidden', '--vimgrep', '--heading', '-S'})
  vim.fn['coc#config']('session.directory', vim.fn.stdpath('data')..'/session') -- in startify autoload/startify.vim
  -- {{{4 coc json
  -- json schemas
  local pluginPath = vim.fn.stdpath('data') .. '/site/pack/packer/start'
  local fileUrlPath = string.format('file://%s', pluginPath)
  vim.fn['coc#config']('json.schemas', {
    {
      fileMatch = { '.vimspector.json' },
      url = fileUrlPath .. '/vimspector/docs/schema/vimspector.schema.json',
    },
    {
      fileMatch = { '.gadgets.json', '.gadgets.d/*.json' },
      url = fileUrlPath .. '/vimspector/docs/schema/gadgets.schema.json',
    }
  })
  -- {{{4 coc eslint
  vim.fn['coc#config']('eslint', {
    filetypes = {}
  })
  -- {{{4 coc highlight
  vim.fn['coc#config']('highlight', {
    colors = {
      enable = false,
    },
    document = {
      enable = false,
    },
  })
  -- {{{4 coc rust
  vim.fn['coc#config']('rust-analyzer', {
    enable = true
  })
  --- {{{4 coc go
  -- temporary disable go lsp
  vim.fn['coc#config']('go', {
    enable = false
  })
  -- {{{4 coc sumneko lua
  vim.fn['coc#config']('sumneko-lua', {
    enableNvimLuaDev = true,
  })
  vim.fn['coc#config']('Lua', {
    completion = {
      -- keywordSnippet = "Disable"
    },
    diagnostics = {
      -- disable = { 'lowercase-global', 'different-requires' }
    },
    workspace = {
      checkThirdParty = false,
      library = {}
    },
    telemetry = {
      enable = false,
    },
  })

  -- {{{3 coc-extension list
  vim.g.coc_global_extensions = {
    'coc-browser',
    'coc-clangd',
    'coc-css',
    'coc-cssmodules',
    'coc-eslint',
    'coc-explorer',
    'coc-git',
    'coc-go',
    'coc-highlight',
    'coc-json',
    'coc-lists',
    'coc-markdownlint',
    'coc-pairs',
    'coc-prettier',
    'coc-protobuf',
    'coc-rust-analyzer',
    'coc-sh',
    'coc-sumneko-lua',
    'coc-tabnine',
    'coc-tsserver',
    'coc-vetur', -- Vue.js
    'coc-vimlsp',
    'coc-vimtex',
    'coc-yaml',
    'coc-yank'
  }

  -- {{{3 coc-explorer
  function CocExplorerInited(bufnr)
    vim.fn.setbufvar(bufnr, '&number', 1)
    vim.fn.setbufvar(bufnr, '&relativenumber', 1)
  end

  -- use post hook from coc-explorer
  vim.cmd([[
    function! CocExplorerInited(filetype, bufnr)
      call v:lua.CocExplorerInited(a:bufnr)
    endfunction
  ]])

  function CocExplorerCurDir()
    local nodeInfo = vim.fn.CocAction('runCommand', 'explorer.getNodeInfo', 0)
    return vim.fn.fnamemodify(nodeInfo.fullpath, ':h')
  end

  function CocExecCurDir(cmd)
    local dir = CocExplorerCurDir()
    vim.fn.execute('cd ' .. dir)
    vim.fn.execute(cmd)
  end

  function CocInitExplorer()
    local bMap = vim.api.nvim_buf_set_keymap
    vim.opt.winblend = 10

    -- Integration with other plugins

    -- CocList
    bMap(0, 'n', '<Leader>fg', ':call v:lua.CocExecCurDir("CocList -I grep")<CR>', {noremap = true})
    bMap(0, 'n', '<Leader>fG', ':call v:lua.CocExecCurDir("CocList -I grep -regex")<CR>', {noremap = true})
    bMap(0, 'n', '<C-p>', ':call v:lua.CocExecCurDir("CocList files")<CR>', {noremap = true})

    -- vim-floaterm
    bMap(0, 'n', '<Leader>ft', ':call v:lua.CocExecCurDir("FloatermNew --wintype=floating")<CR>', {noremap = true})
  end

  vim.cmd([[
    augroup CocExplorerCustom
      autocmd!
      " autocmd BufEnter * call <SID>enter_explorer()
      autocmd FileType coc-explorer call v:lua.CocInitExplorer()
      autocmd User CocExplorerOpenPost call v:lua.CocExplorerInited()
    augroup END
  ]])

  vim.g.coc_explorer_global_presets = {
    workspace = {
      position = 'floating',
      toggle = true,
      ['quit-on-open'] = true
    }
  }

  vim.cmd([[
    augroup mycocgroup
      autocmd!
      " Setup formatexpr specified filetype(s).
      autocmd FileType typescript,json setl formatexpr=CocAction('formatSelected')
      " Update signature help on jump placeholder.
      autocmd User CocJumpPlaceholder call CocActionAsync('showSignatureHelp')
    augroup end
  ]])
end

function M.mappings()
  local map = utils.map
  local wk = require('which-key')
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
  map('n', '[e', '<Plug>(coc-diagnostic-prev-error)', noNoremap)
  map('n', ']e', '<Plug>(coc-diagnostic-next-error)', noNoremap)
  -- jump to float window
  map('n', 'gw', '<plug>(coc-float-jump)', noNoremap)
  -- close all coc.nvim float window
  map('n', '<leader>cw', '<plug>(coc-float-hide)', noNoremap)
  -- GoTo code navigation.
  map('n', 'gd', '<Plug>(coc-definition)', noNoremap)
  map('n', 'gy', '<Plug>(coc-type-definition)', noNoremap)
  map('n', 'gi', '<Plug>(coc-implementation)', noNoremap)
  map('n', 'gr', '<Plug>(coc-references)', noNoremap)
  -- Use K to show documentation in preview window.
  map('n', 'K', ':call v:lua.CocShowDocumentation()<CR>')
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
  vim.cmd([[command! -nargs=0 Format :call CocAction('format')]]) -- `:Format` format current buffer
  -- `:Fold` fold current buffer
  vim.cmd([[command! -nargs=? Fold :call     CocAction('fold', <f-args>)]])
  -- `:OR` organize imports
  vim.cmd([[command! -nargs=0 OR :call CocAction('runCommand', 'editor.action.organizeImport')]])
  -- quickfix action
  map('n', '<leader>cf', '<plug>(coc-fix-current)')
  -- diagnostic
  map('n', '<leader>cd', '<plug>(coc-diagnostic-info)')
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
  -- map('n', '<leader>l', ':<C-u>CocList <CR>')
  map('n', '<leader>y', ':<C-u>CocList -A --normal yank<cr>')
  map('n', '<leader>b', ':<C-u>CocList --normal buffers<CR>')
  wk.register({
    name = 'CocList',
    b = { '<cmd>CocList buffers<CR>', 'buffers' },
    c = { '<cmd>CocList commands<CR>', 'coc commands' },
    d = { '<cmd>CocList diagnostics<CR>', 'diagnostics' },
    f = { '<cmd>CocList files<CR>', 'files' },
    g = { '<cmd>CocList grep<CR>', 'grep content' },
    l = { '<cmd>CocListResume<CR>', 'last view' },
    o = { '<cmd>CocList outline<CR>', 'symbols in current document' },
    s = { '<cmd>CocList -I symbols<CR>', 'workspace symbols' },

  }, { prefix = '<leader>l'})
end

function _G.CheckBackSpace()
  local col = vim.fn.col('.') - 1
  return col <= 0 or vim.fn.getline('.'):sub(col, col):match('%s')
end

function _G.CocTab()
  if vim.fn.pumvisible() ~= 0 then
    return utils.esc('<C-n>')
  elseif _G.CheckBackSpace() then
      return utils.esc('<TAB>')
    else
      return vim.fn['coc#refresh']()
  end
end

function _G.CocSTab()
  if vim.fn.pumvisible() then
    return utils.esc('<C-p>')
  else
    return utils.esc('<C-h>')
  end
end

function _G.CocEnterConfirm()
  if vim.fn.pumvisible() ~= 0 then
    return vim.fn['coc#_select_confirm']()
  else
    return utils.esc("<C-g>u<CR><C-R>=coc#on_enter()<CR>")
  end
end

function _G.CocShowDocumentation()
  if vim.fn.index({'vim', 'help'}, vim.bo.filetype) >= 0 then
    vim.cmd('h ' .. vim.fn.expand('<cword>'))
  elseif vim.fn['coc#rpc#ready']() then
    vim.fn.CocActionAsync('doHover')
  else
    vim.cmd('!' .. vim.o.keywordprg .. ' ' .. vim.fn.expand('<cword>'))
  end
end

return M
