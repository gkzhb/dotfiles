local M = {}
local utils = require('utils')

function M.init()
  -- {{{2 coc.vim config
  -- {{{3 coc-settings.json
  -- help: coc#config()
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
  -- {{{4 coc rust
  vim.fn['coc#config']('rust-analyzer', {
    enable = true
  })
  --- {{{4 coc go
  -- temporary disable go lsp
  vim.fn['coc#config']('go', {
    enable = false
  })
  -- {{{4 coc lua
  vim.fn['coc#config']('Lua', {
    completion = {
      keywordSnippet = "Disable"
    },
    diagnostics = {
      disable = { 'lowercase-global', 'different-requires' }
    },
    workspace = {
      checkThirdParty = false,
      library = {}
    }
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
    'coc-lua',
    'coc-markdownlint',
    'coc-pairs',
    'coc-prettier',
    'coc-protobuf',
    'coc-rust-analyzer',
    'coc-sh',
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
end

function checkBackSpace()
  local col = vim.fn.col('.') - 1
  return col <= 0 or vim.fn.getline('.'):sub(col, col):match('%s')
end

function CocTab()
  if vim.fn.pumvisible() ~= 0 then
    return utils.esc('<C-n>')
  elseif checkBackSpace() then
      return utils.esc('<TAB>')
    else
      return vim.fn['coc#refresh']()
  end
end

function CocSTab()
  if vim.fn.pumvisible() then
    return utils.esc('<C-p>')
  else
    return utils.esc('<C-h>')
  end
end

function CocEnterConfirm()
  if vim.fn.pumvisible() ~= 0 then
    return vim.fn['coc#_select_confirm']()
  else
    return utils.esc("<C-g>u<CR><C-R>=coc#on_enter()<CR>")
  end
end

function CocShowDocumentation()
  if vim.fn.index({'vim', 'help'}, vim.o.filetype) > 0 then
    vim.cmd('h ' .. vim.fn.expand('<cword>'))
  elseif vim.fn['coc#rpc#ready']() then
    vim.fn.CocActionAsync('doHover')
  else
    vim.cmd('!' .. vim.o.keywordprg .. ' ' .. vim.fn.expand('<cword>'))
  end
end

return M
