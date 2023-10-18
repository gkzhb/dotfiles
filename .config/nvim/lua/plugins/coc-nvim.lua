local M = {}
local utils = require('utils')

function _G.CocCodeActionMapping(cmd, ...)
  local ret = function()
    vim.fn['CocAction'](cmd, unpack(arg))
  end
  return ret
end

function M.init()
  -- {{{2 coc.vim config
  --
  -- {{{3 config variables
  -- coc-extension list
  vim.g.coc_global_extensions = {
    'coc-browser',
    'coc-clangd',
    'coc-css',
    'coc-cssmodules',
    'coc-deno',
    'coc-eslint',
    'coc-explorer',
    'coc-git',
    'coc-go',
    'coc-highlight',
    'coc-jedi',
    'coc-json',
    'coc-lists',
    'coc-markdownlint',
    -- 'coc-pairs',
    'coc-prettier',
    'coc-protobuf',
    'coc-react-refactor',
    'coc-rust-analyzer',
    'coc-sh',
    'coc-snippets',
    'coc-sumneko-lua',
    'coc-stylua',
    'coc-tabnine',
    'coc-tsserver',
    'coc-vetur', -- Vue.js
    'coc-vimlsp',
    'coc-vimtex',
    'coc-yaml',
    'coc-yank',
  }

  -- {{{3 coc-settings.json
  -- help: coc#config()
  vim.fn['coc#config']('coc', {
    preferences = {
      colorSupport = false, -- coc-highlight
    },
  })
  -- {{{4 codeLens
  vim.fn['coc#config']('codeLens', {
    enable = true,
    position = 'eol',
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
      ['<cr>'] = { 'wait', 'expandable?', 'expanded?', 'collapse', 'expand', 'open' },
      cd = { 'cd' },
      m = 'actionMenu',
      mc = 'copyFile',
      C = 'copyFile',
      md = 'delete',
      D = 'delete',
      H = { 'wait', 'gotoParent' },
      L = { 'cd' },
    },
  })
  -- {{{4 coc lists
  vim.fn['coc#config']('list.source.grep.args', { '--hidden', '--vimgrep', '--heading', '-S' })
  vim.fn['coc#config']('session.directory', vim.fn.stdpath('data') .. '/session') -- in startify autoload/startify.vim
  -- vim.g.coc_enable_locationlist = 0
  -- vim.cmd([[autocmd User CocLocationsChange CocList --no-quit --first --normal location]])
  -- {{{4 coc json
  -- json schemas
  local pluginPath = require('utils.packer').pluginPath
  local fileUrlPath = string.format('file://%s', pluginPath)
  vim.fn['coc#config']('json.schemas', {
    {
      fileMatch = { '.vimspector.json' },
      url = fileUrlPath .. '/vimspector/docs/schema/vimspector.schema.json',
    },
    {
      fileMatch = { '.gadgets.json', '.gadgets.d/*.json' },
      url = fileUrlPath .. '/vimspector/docs/schema/gadgets.schema.json',
    },
  })
  -- {{{4 coc tsserver
  vim.fn['coc#config']('tsserver', {
    enable = true,
  })
  vim.fn['coc#config']('typescript', {
    inlayHints = {
      functionLikeReturnTypes = {
        enabled = true,
      }
    }
  })
  -- {{{4 coc eslint
  vim.fn['coc#config']('eslint', {
    filetypes = {},
  })
  -- {{{4 coc eslint
  vim.fn['coc#config']('react-refactor', {
    produceClass = false,
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
  vim.g.coc_default_semantic_highlight_groups = 1

  -- {{{4 coc rust
  vim.fn['coc#config']('rust-analyzer', {
    enable = true,
  })
  --- {{{4 coc go
  -- temporary disable go lsp
  vim.fn['coc#config']('go', {
    enable = false,
  })
  -- {{{4 coc sumneko lua
  vim.fn['coc#config']('sumneko-lua', {
    enableNvimLuaDev = true,
    checkUpdate = false,
  })

  -- {{{4 coc-explorer
  function _G.CocExplorerInited(bufnr)
    vim.fn.setbufvar(bufnr, '&number', 1)
    vim.fn.setbufvar(bufnr, '&relativenumber', 1)
  end

  -- use post hook from coc-explorer
  vim.cmd([[
    function! CocExplorerInited(filetype, bufnr)
      call v:lua.CocExplorerInited(a:bufnr)
    endfunction
  ]])

  function _G.CocExplorerCurDir()
    local nodeInfo = vim.fn.CocAction('runCommand', 'explorer.getNodeInfo', 0)
    return vim.fn.fnamemodify(nodeInfo.fullpath, ':h')
  end

  function _G.CocExecCurDir(cmd)
    local dir = CocExplorerCurDir()
    vim.fn.execute('cd ' .. dir)
    vim.fn.execute(cmd)
  end

  function _G.CocInitExplorer()
    local bMap = vim.api.nvim_buf_set_keymap
    vim.opt.winblend = 10

    -- Integration with other plugins

    -- CocList
    bMap(0, 'n', '<Leader>fg', ':call v:lua.CocExecCurDir("CocList -I grep")<CR>', { noremap = true })
    bMap(0, 'n', '<Leader>fG', ':call v:lua.CocExecCurDir("CocList -I grep -regex")<CR>', { noremap = true })
    bMap(0, 'n', '<C-p>', ':call v:lua.CocExecCurDir("CocList files")<CR>', { noremap = true })

    -- vim-floaterm
    bMap(0, 'n', '<Leader>ft', ':call v:lua.CocExecCurDir("FloatermNew --wintype=floating")<CR>', { noremap = true })
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
      ['quit-on-open'] = true,
    },
  }

  vim.cmd([[
    augroup mycocgroup
      autocmd!
      " Setup formatexpr specified filetype(s).
      autocmd FileType typescriptreact,typescript,go,rust,json,lua,javascript,javascriptreact setl formatexpr=CocAction('formatSelected')
      " Update signature help on jump placeholder.
      autocmd User CocJumpPlaceholder call CocActionAsync('showSignatureHelp')
    augroup end
  ]])
end

function M.mappings()
  local wk = require('which-key')
  wk.register({
    ['<TAB>'] = { 'v:lua.CocTab()', '' },
    ['<S-TAB>'] = { 'v:lua.CocSTab()', '' },
    ['<CR>'] = { 'v:lua.CocEnterConfirm()', '' },
  }, { mode = 'i', expr = true, nowait = true })

  -- Use `[g` and `]g` to navigate diagnostics
  -- Use `:CocDiagnostics` to get all diagnostics of current buffer in location list.
  wk.register({
    g = { '<Plug>(coc-diagnostic-prev)', 'prev diagnostic' },
    e = { '<Plug>(coc-diagnostic-prev-error)', 'prev error' },
  }, { mode = 'n', prefix = '[' })
  wk.register({
    g = { '<Plug>(coc-diagnostic-next)', 'next diagnostic' },
    e = { '<Plug>(coc-diagnostic-next-error)', 'next error' },
  }, { mode = 'n', prefix = ']' })
  wk.register({
    name = 'goto somewhere',
    w = { '<plug>(coc-float-jump)', 'jump to coc float window' },
    -- GoTo code navigation.
    d = { '<cmd>call CocAction("jumpDefinition")<CR>', 'goto code definition' },
    ds = { '<cmd>call CocAction("jumpDefinition", "split")<CR>', 'code definition in split window' },
    dv = { '<cmd>call CocAction("jumpDefinition", "vsplit")<CR>', 'code definition in vsplit window' },
    dt = { '<cmd>call CocAction("jumpDefinition", "tabe")<CR>', 'code definition in new tab' },
    dq = { '<cmd>call CocAction("jumpDefinition", "quickfix")<CR>', 'code definition in quickfix' },
    dp = { '<cmd>call CocAction("jumpDefinition", "preview")<CR>', 'code definition in preview' },
    y = { '<cmd>call CocAction("jumpTypeDefinition")<CR>', 'goto type definition' },
    i = { '<cmd>call CocAction("jumpImplementation")<CR>', 'goto implementation' },
    r = {
      '<Plug>(coc-references)',
      'references',
    },
    rr = {
      '<cmd>lua require("telescope").extensions.coc.references({ initial_mode = "normal"})<cr>',
      'references with telescope',
    },
  }, { mode = 'n', prefix = 'g' })
  wk.register({
    name = 'coc list related',
    n = { '<cmd>CocNext<CR>', 'jump to next coc list item' },
    p = { '<cmd>CocPrev<CR>', 'jump to previous coc list item' },
  }, { mode = 'n', prefix = '<leader>c' })

  -- current cursor reltead
  wk.register({
    d = { CocCodeActionMapping('definitionHover'), 'show definition' },
    K = { '<cmd>call v:lua.CocShowDocumentation()<CR>', 'show documentation in preview window' },
    g = { CocCodeActionMapping('diagnosticInfo'), 'show diagnostic message' },
  }, { mode = 'n', prefix = 'K' })
  wk.register({
    k = {
      name = 'symbol under cursor',
      c = { '<cmd>call v:lua.CocAction("pickColor")<CR>', 'pick color' },
      k = { '<cmd>call v:lua.CocAction("definitionHover")<CR>', 'get definition' },
      d = { CocCodeActionMapping('diagnosticInfo'), 'show diagnostic message' },
      p = { '<cmd>call v:lua.CocAction("pickColor")<CR>', 'pick color' },
      v = { '<cmd>call v:lua.CocAction("doHover")<CR>', 'get info' },
    },
  }, { mode = 'n', prefix = '<Leader>' })
  -- Highlight the symbol and its references when holding the cursor.
  vim.cmd([[
    autocmd CursorHold * silent call CocActionAsync('highlight')
  ]])

  -- see in *coc-code-actions*
  local actionMappings = {
    name = 'coc actions',
    a = {
      name = 'code actions',
      a = { '<Plug>(coc-codeaction)', 'CodeAction for file' },
      e = { '<Plug>(coc-codeaction-refactor)', 'CodeAction refactor' },
      k = { '<Plug>(coc-codeaction-cursor)', 'CodeAction under cursor' },
      l = { '<Plug>(coc-codeaction-line)', 'CodeAction for line' },
      s = { '<Plug>(coc-codeaction-source)', 'source CodeAction' },
      v = { '<Plug>(coc-codeaction-selected)', 'apply codeAction to selected region' },
      -- Example: `<leader>aap` for current paragraph
    },
    c = { '<Plug>(coc-codeaction-cursor)', 'CodeAction under cursor' },
    cc = { '<Plug>(coc-codeaction)', 'CodeAction for file' },
    e = { CocCodeActionMapping('refactor'), 'refactor symbol' },
    k = { '<Plug>(coc-codeaction-cursor)', 'CodeAction under cursor' },
    l = { '<Plug>(coc-codelens-action)', 'CodeLens Action' },
    f = { '<Plug>(coc-fix-current)', 'apply autofix on current line' },
    fc = { '<Plug>(coc-format-selected)', 'format selected code' },
    r = { '<Plug>(coc-rename)', 'rename symbol' },
  }
  wk.register({
    name = 'coc related',
    a = actionMappings,
    d = { '<Plug>(coc-diagnostic-info)', 'diagnostic info' },
    da = { CocCodeActionMapping('diagnosticList'), 'diagnostic list' },
    fc = { '<Plug>(coc-float-hide)', 'close all coc float window' },
    o = { CocCodeActionMapping('showOutline'), 'show coc outline', noremap = true },
    v = {
      name = 'enhanced views',
      c = {
        name = 'call hierarchy', -- see *coc-callHierarchy*
        i = { CocCodeActionMapping('showIncomingCalls'), 'incoming call hierarchy' },
        o = { CocCodeActionMapping('showOutgoingCalls'), 'outgoing call hierarchy' },
      },
      t = {
        name = 'type hierarchy',
        p = { CocCodeActionMapping('showSuperTypes'), 'super type hierarchy' },
        c = { CocCodeActionMapping('showSubTypes'), 'sub type hierarchy' },
      },
    },
    w = {
      name = 'coc workspace',
      r = { '<cmd>:CocCommand workspace.redo<CR>', 'redo' },
      u = { '<cmd>:CocCommand workspace.undo<CR>', 'undo' },
    },
  }, { mode = 'n', prefix = '<Leader>l' })
  wk.register(actionMappings, { mode = 'n', prefix = '<Leader>a' })

  wk.register({
    f = { '<Plug>(coc-format-selected)', 'format selected code' },
    a = { '<Plug>(coc-codeaction-selected)', 'apply codeAction to selected region' },
    x = { '<Plug>(coc-convert-snippet)', 'convert selected code to snippet' }, -- coc-snippets
  }, { mode = 'x', prefix = '<Leader>' })
  wk.register({
    f = { '<Plug>(coc-format-selected)', 'format selected code' },
  }, { mode = 'v', prefix = '<Leader>' })
  -- coc-snippets
  wk.register({
    ['<C-j>'] = { '<Plug>(coc-snippets-select)', 'select text for visual placeholder' },
  }, { mode = 'v' })
  wk.register({
    ['<C-l>'] = { '<cmd>call v:lua.CocSnippetsExpand()<CR>', 'expand snippet' },
    ['<C-j>'] = { '<cmd>call v:lua.CocSnippetsExpandJump()<CR>', 'expand snippet and jump' },
  }, { mode = 'i' })

  -- `:Format` format current buffer
  vim.cmd([[command! -nargs=0 Format :call CocAction('format')]])
  -- `:Fold` fold current buffer
  vim.cmd([[command! -nargs=? Fold :call CocAction('fold', <f-args>)]])
  -- `:OR` organize imports
  vim.cmd([[command! -nargs=0 OR :call CocAction('runCommand', 'editor.action.organizeImport')]])

  -- Map function and class text objects
  -- NOTE: Requires 'textDocument.documentSymbol' support from the language server.
  wk.register({
    ['if'] = { '<Plug>(coc-funcobj-i)', 'Select inside function' },
    af = { '<Plug>(coc-funcobj-a)', 'Select around function' },
    ic = { '<Plug>(coc-classobj-i)', 'Select inside class/struct/interface' },
    ac = { '<Plug>(coc-classobj-a)', 'Select around class/struct/interface' },
  }, { mode = 'x' })
  wk.register({
    ['if'] = { '<Plug>(coc-funcobj-i)', 'Select inside function' },
    af = { '<Plug>(coc-funcobj-a)', 'Select around function' },
    ic = { '<Plug>(coc-classobj-i)', 'Select inside class/struct/interface' },
    ac = { '<Plug>(coc-classobj-a)', 'Select around class/struct/interface' },
  }, { mode = 'o' })

  -- scroll float window
  wk.register({
    ['<C-f>'] = { 'coc#float#has_scroll() ? coc#float#scroll(1) : "<C-f>"', 'float window scroll down' },
    ['<C-b>'] = { 'coc#float#has_scroll() ? coc#float#scroll(0) : "<C-b>"', 'float window scroll up' },
  }, { mode = 'n', expr = true, nowait = true })
  wk.register({
    ['<C-f>'] = {
      'coc#float#has_scroll() ? "<c-r>=coc#float#scroll(1)<cr>" : "<Right>"',
      'float window scroll down',
    },
    ['<C-b>'] = {
      'coc#float#has_scroll() ? "<c-r>=coc#float#scroll(0)<cr>" : "<Left>"',
      'float window scroll up',
    },
  }, { mode = 'i', expr = true, nowait = true })

  -- wk.register({
  --   e = { CocCodeActionMapping('runCommand', 'explorer', '--preset', 'workspace', vim.fn.getcwd()), 'coc explorer' },
  --   y = { ':<C-u>CocList -A --normal yank<CR>', 'coc yank list' },
  -- }, { mode = 'n', prefix = '<Leader>' })

  -- coc lists
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
  }, { mode = 'n', prefix = '<leader>ll' })
end

function _G.CheckBackSpace()
  local col = vim.fn.col('.') - 1
  return col <= 0 or vim.fn.getline('.'):sub(col, col):match('%s')
end

function _G.CocTab()
  if vim.fn['coc#expandableOrJumpable']() then
    return utils.esc('<C-r>=coc#rpc#request("doKeymap", ["snippets-expand-jump", ""])<CR>')
  end
  if vim.fn.pumvisible() ~= 0 then
    return utils.esc('<C-n>')
  end
  if _G.CheckBackSpace() then
    return utils.esc('<TAB>')
  end
  return vim.fn['coc#refresh']()
end

function _G.CocSTab()
  if vim.fn.pumvisible() then
    return utils.esc('<C-p>')
  end
  return utils.esc('<C-h>')
end

function _G.CocEnterConfirm()
  if vim.fn['coc#pum#visible']() ~= 0 then
    return vim.fn['coc#_select_confirm']()
  end
  return utils.esc('<C-g>u<CR><C-r>=coc#on_enter()<CR>')
end

function _G.CocAction(cmd, ...)
  if vim.fn['coc#rpc#ready']() then
    vim.fn.CocActionAsync(cmd, unpack(arg))
  else
    vim.api.nvim_echo('CocAction:: coc rpc not ready: ' + cmd, false, {})
  end
end

function _G.CocGetHover()
  if not vim.fn['coc#rpc#ready']() then
    return
  end
  -- getHover returns info the same as doHover
  local list = vim.fn.CocAction('getHover')
  for idx, item in pairs(list) do
    print(idx, item)
  end
  print(list)
  -- vim.notify(list)
end

function _G.CocShowDocumentation()
  if vim.fn.index({ 'vim', 'help' }, vim.bo.filetype) >= 0 then
    vim.cmd('h ' .. vim.fn.expand('<cword>'))
    return
  end
  if vim.fn['coc#rpc#ready']() then
    vim.fn.CocActionAsync('doHover')
    return
  end
  vim.cmd('!' .. vim.o.keywordprg .. ' ' .. vim.fn.expand('<cword>'))
end

function _G.CocSnippetsExpand()
  if not vim.fn['coc#expandable']() then
    return
  end
  vim.fn['coc#rpc#request']('doKeymap', { 'snippets-expand', '' })
end

function _G.CocSnippetsExpandJump()
  if not vim.fn['coc#expandableOrJumpable']() then
    return
  end
  vim.fn['coc#rpc#request']('doKeymap', { 'snippets-expand-jump', '' })
end
return M
