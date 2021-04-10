" vim: set fdm=marker: 

" {{{1 Pre Plugin Settings
set nocompatible  "去掉讨厌的有关vi一致性模式，避免以前版本的一些bug和局限
filetype off

" {{{1 Plugins
call plug#begin()

" {{{2 color theme
" Plug 'altercation/vim-colors-solarized'
" let g:solarized_termtrans=1
Plug 'cocopon/iceberg.vim'
Plug 'joshdick/onedark.vim'

" {{{2 language related
" language highlight
let g:polyglot_disabled = ['sensible']
Plug 'sheerun/vim-polyglot'

" ts js
Plug 'leafgarland/typescript-vim'
Plug 'peitalin/vim-jsx-typescript'
Plug 'lukaszb/vim-web-indent'
" let g:js_indent = '/location/to/javascript.vim'

" latex
Plug 'lervag/vimtex'

" comment 注释
Plug 'tpope/vim-commentary' 

" Plug 'leafOfTree/vim-vue-plugin' " vue

" Plug 'mzlogin/vim-markdown-toc'
" Markdown TOC 生成 https://mazhuang.org/2015/12/19/vim-markdown-toc/
" :GenTocGFM 在光标处生成 GFM 风格的 Table of Contents
" :RemoveToc 删除插件生成的 TOC

" {{{2 display enhancement
if executable('go')
  " 显示颜色 Golang is needed to compile it
  Plug 'rrethy/vim-hexokinase', { 'do': 'make hexokinase' }
endif
" 方便编辑颜色
Plug 'Rykka/colorv.vim'
" colorv 依赖 needed for fetching schemes online.
Plug 'mattn/webapi-vim' 
" VCS 文件修改情况显示
Plug 'mhinz/vim-signify' 
" statusline
Plug 'itchyny/lightline.vim'
" start screen 启动屏
Plug 'mhinz/vim-startify' 
" 缩进线条 indent visualization
Plug 'Yggdroot/indentLine'

Plug 'liuchengxu/vista.vim' " 
" preview the result of replace command in real time
" 实时预览替换命令执行效果
Plug 'markonm/traces.vim' 

" needed by lf
Plug 'voldikss/vim-floaterm'
" lf 插件
Plug 'ptzz/lf.vim'

" denite: list all resources
if has('nvim')
  Plug 'Shougo/denite.nvim', { 'do': ':UpdateRemotePlugins' }
else
  Plug 'Shougo/denite.nvim'
  Plug 'roxma/nvim-yarp'
  Plug 'roxma/vim-hug-neovim-rpc'
endif

" 浏览器中使用 neovim
Plug 'glacambre/firenvim', { 'do': { _ -> firenvim#install(0) } }

" {{{2 movement
Plug 'christoomey/vim-tmux-navigator'
" Move to window just like tmux by specifying number of window
Plug 't9md/vim-choosewin' 
Plug 'easymotion/vim-easymotion' " 移动光标
Plug 'szw/vim-maximizer' " 最大化窗口
Plug 'majutsushi/tagbar'
" Plugin 'lvht/tagbar-markdown'

" {{{2 git related
Plug 'tpope/vim-fugitive' " vim 中使用 git 的增强插件
Plug 'junegunn/gv.vim' " git commit browser
Plug 'sodapopcan/vim-twiggy' " git branch push/pull/rebase


" {{{2 lsp related
Plug 'neoclide/coc.nvim', {'branch': 'release'}

" {{{3 coc extensions
" extensions are removed from vim-plug
"
" Plug 'neoclide/coc-lists', {'do': 'yarn install --frozen-lockfile'}
" Plug 'neoclide/coc-tabnine', {'do': 'yarn install --frozen-lockfile'}
" Plug 'neoclide/coc-prettier', {'do': 'yarn install --frozen-lockfile'}
" Plug 'weirongxu/coc-explorer', {'do': 'yarn install --frozen-lockfile'}
" Plug 'neoclide/coc-eslint', {'do': 'yarn install --frozen-lockfile'}
" Plug 'neoclide/coc-highlight', {'do': 'yarn install --frozen-lockfile'}
" Plug 'neoclide/coc-yank', {'do': 'yarn install --frozen-lockfile'}
" Plug 'neoclide/coc-git', {'do': 'yarn install --frozen-lockfile'}

" language
" Plug 'neoclide/coc-yaml', {'do': 'yarn install --frozen-lockfile'}
" Plug 'neoclide/coc-json', {'do': 'yarn install --frozen-lockfile'}
" Plug 'neoclide/coc-css', {'do': 'yarn install --frozen-lockfile'}
" Plug 'antonk52/coc-cssmodules', {'do': 'yarn install --frozen-lockfile'}
" Plug 'iamcco/coc-vimlsp', {'do': 'yarn install --frozen-lockfile'}
" Plug 'neoclide/coc-tsserver', {'do': 'yarn install --frozen-lockfile'}
" Plug 'josa42/coc-go', {'do': 'yarn install --frozen-lockfile'}
" Plug 'neoclide/coc-vetur', {'do': 'yarn install --frozen-lockfile'} " vue
" Plug 'fannheyward/coc-markdownlint', {'do': 'yarn install --frozen-lockfile'}
" Plug 'josa42/coc-sh', {'do': 'yarn install --frozen-lockfile'}

" }}}

" {{{2 others
if executable('sudo')
  " sudo read/write files
  Plug 'lambdalisue/suda.vim'
endif

" }}}

" 你的所有插件需要在下面这行之前
call plug#end()
" }}}

" {{{1 Plugin Configure

" {{{2 polyglot
let g:vim_json_syntax_conceal = 0
let g:vim_markdown_conceal = 0
let g:vim_markdown_conceal_code_blocks = 0
let g:tex_conceal = ""
let g:vim_markdown_math = 1
let g:vim_markdown_conceal_code_blocks = 0

" {{{2 hexokinase
" let g:Hexokinase_highlighters = ['foreground']
" Filetype specific patterns to match
" entry value must be comma seperated list
let g:Hexokinase_ftOptInPatterns = {
    \ 'css': 'full_hex,rgb,rgba,hsl,hsla,colour_names',
    \ 'html': 'full_hex,rgb,rgba,hsl,hsla,colour_names',
    \ 'vim': 'full_hex,rgb,colour_names'
    \ }

" {{{2 vim tmux navigator
" Disable tmux navigator when zooming the Vim pane
let g:tmux_navigator_disable_when_zoomed = 1

" {{{2 vim tex
" let g:vimtex_compiler_latexmk = {}
" let g:vimtex_imaps_leader = '@'
let g:tex_flavor = 'latex'
" To prevent conceal in LaTeX files
let g:vimtex_syntax_conceal_default=0
" enable folding in latex
let g:vimtex_fold_enabled = 1

" {{{2 lightline

" {{{3 statusline
set noshowmode " 隐藏最下方显示当前模式

let g:statuslinebreakpoint = 45
let g:lightline = {
  \ 'colorscheme': 'onedark',
  \ 'active': {
    \   'left': [ [ 'mode', 'paste' ],
    \             [ 'bufnum' ],
    \             [ 'modified', 'filename', 'readonly' ],
    \             [ 'fileencoding', 'fileformat'] ],
    \   'right': [ [ 'percent' ], [ 'lineinfo' ], [ 'filetype' ], [ 'gitbranch' ], [ 'cocstatus' ] ]
    \ },
  \ 'inactive': {
    \   'left': [ [ 'mode', 'paste' ],
    \             [ 'bufnum' ],
    \             [ 'modified', 'filename', 'readonly' ],
    \             [ 'fileencoding', 'fileformat'] ],
    \   'right': [ [ 'percent' ], [ 'lineinfo' ], [ 'filetype' ] ]
    \ },
  \ 'component': {
    \ 'mode': '%{winwidth(0)>g:statuslinebreakpoint?lightline#mode():""}',
    \ 'fileencoding': '%{winwidth(0)>g:statuslinebreakpoint?toupper(&fenc!=#""?&fenc:&enc):""}',
    \ 'fileformat': '%{winwidth(0)>g:statuslinebreakpoint?toupper(&ff):""}',
    \ 'filetype': '%{&ft!=#""?&ft:"none"}',
    \ 'modified': '%{winwidth(0)>g:statuslinebreakpoint?(&modified?"+":&modifiable?"":"-"):""}',
    \ 'paste': '%{(winwidth(0)>g:statuslinebreakpoint && &paste)?"PASTE":""}',
    \ 'readonly': '%{(winwidth(0)>g:statuslinebreakpoint && &ro)?"RO":""}',
    \ 'gitbranch': '%{winwidth(0)>g:statuslinebreakpoint?FugitiveHead():""}',
    \ 'lineinfo': '%{winwidth(0)>g:statuslinebreakpoint?printf("%3s:%-2s", line("."), col(".")):""}',
    \ 'cwd': '%{getcwd()}',
    \ },
  \ 'component_function': {
    \ 'filename': 'LightlineRelativePathFileName',
    \ 'cocstatus': 'StatusDiagnostic',
    \ },
  \ 'component_visible_condition': {
    \ },
  \ 'component_function_visible_condition': {
    \ },
  \ 'subseparator': { 'left': '', 'right': '' },
  \ 'mode_map': {
    \ 'n' : 'N',
    \ 'i' : 'I',
    \ 'R' : 'R',
    \ 'v' : 'V',
    \ 'V' : 'VL',
    \ "\<C-v>": 'VB',
    \ 'c' : 'C',
    \ 's' : 'S',
    \ 'S' : 'SL',
    \ "\<C-s>": 'SB',
    \ 't': 'T',
    \ },
  \ }

" trim string on different position([l]eft, [r]ight or [c]enter)
" @overflow: how to describe trimmed string
function! s:trimString(str, maxlen, position) abort
  let position = get(a:, 'position', 'l') " position='l' by default
  const overflow = '...'
  if len(a:str) < a:maxlen
    return a:str
  endif
  if position == 'l'
    return overflow . a:str[len(a:str) - a:maxlen + 3:]
  endif
  if position == 'r'
    return a:str[:a:maxlen - 3] . overflow
  endif
  if position == 'c'
    let halflen = (a:maxlen - 3) / 2
    return a:str[:halflen - 1] . overflow . a:str[len(a:str) - halflen:]
  endif
  return a:str " incorrect position value
endfunction

function! LightlineRelativePathFileName() abort
  let width = winwidth(0)
  return width > g:statuslinebreakpoint
    \ ? width > 80 ? s:trimString(expand("%:."), width / 3, 'l') : s:trimString(expand("%:."), width / 2, 'l')
    \ : ""
endfunction

function! StatusDiagnostic() abort
  let info = get(b:, 'coc_diagnostic_info', {})
  if empty(info) | return '' | endif
  let msgs = []
  if get(info, 'error', 0)
  call add(msgs, 'E' . info['error'])
  endif
  if get(info, 'warning', 0)
  call add(msgs, 'W' . info['warning'])
  endif
  return join(msgs, ' ')
endfunction

" {{{3 tabline
let g:lightline.tabline = {
  \ 'left': [ [ 'tabs' ] ],
  \ 'right': [ [ 'cwd' ] ]
  \ }
let g:lightline.tab = {
  \ 'active': [ 'tabnum', 'modified', 'filename' ],
  \ 'inactive': [ 'tabnum', 'modified', 'filename' ]
  \ }

" }}}

" {{{2 startify
" session directory, default to `$XDG_DATA_HOME/nvim/session`
" should be the same as Coc Session 'session.directory' in coc-settings.json
"
" let g:startify_session_dir = '$XDG_DATA_HOME/nvim/session'
" do not change cwd when opening files
let g:startify_change_to_dir = 0
let g:startify_change_to_vcs_root = 0

" {{{2 firenvim
if exists('g:started_by_firenvim')
  " set font size for firenvim
  set guifont=Monaco:h14:cANSI
endif

" {{{2 lf
let g:lf_map_keys = 0
let g:lf_replace_netrw = 1 " Open lf when vim opens a directory

" {{{2 denite
" ref to https://github.com/ctaylo21/jarvis/blob/master/config/nvim/init.vim#L58
" shortcuts are set in shortcuts section
if executable('rg')
  " if ripgrep is installed, use rg
  call denite#custom#var('file/rec', 'command', ['rg', '--files', '--glob', '!.git'])
  call denite#custom#var('grep', 'command', ['rg'])

  " Custom options for ripgrep
  "   --vimgrep:  Show results with every match on it's own line
  "   --hidden:   Search hidden directories and files
  "   --heading:  Show the file name above clusters of matches from each file
  "   --S:        Search case insensitively if the pattern is all lowercase
  call denite#custom#var('grep', 'default_opts', ['--hidden', '--vimgrep', '--heading', '-S'])

  " Recommended defaults for ripgrep via Denite docs
  call denite#custom#var('grep', 'recursive_opts', [])
  call denite#custom#var('grep', 'pattern_opt', ['--regexp'])
  call denite#custom#var('grep', 'separator', ['--'])
  call denite#custom#var('grep', 'final_opts', [])

endif

" Remove date from buffer list
call denite#custom#var('buffer', 'date_format', '')

" Custom options for Denite
"   split                       - Use floating window for Denite
"   start_filter                - Start filtering on default
"   auto_resize                 - Auto resize the Denite window height automatically.
"   source_names                - Use short long names if multiple sources
"   prompt                      - Customize denite prompt
"   highlight_matched_char      - Matched characters highlight
"   highlight_matched_range     - matched range highlight
"   highlight_window_background - Change background group in floating window
"   highlight_filter_background - Change background group in floating filter window
"   winrow                      - Set Denite filter window to top
"   vertical_preview            - Open the preview window vertically

let s:denite_options = {'default' : {
\ 'split': 'floating',
\ 'start_filter': 1,
\ 'auto_resize': 1,
\ 'source_names': 'short',
\ 'prompt': 'λ ',
\ 'highlight_matched_char': 'Search',
\ 'highlight_matched_range': 'Search',
\ 'winrow': 1,
\ 'vertical_preview': 1
\ }}

" Loop through denite options and enable them
function! s:profile(opts) abort
  for l:fname in keys(a:opts)
    for l:dopt in keys(a:opts[l:fname])
      call denite#custom#option(l:fname, l:dopt, a:opts[l:fname][l:dopt])
    endfor
  endfor
endfunction

call s:profile(s:denite_options)

" {{{2 indent line
let g:indentLine_enabled = 1
" let g:indentLine_showFirstIndentLevel = 1
" let g:indentLine_setColors = 0
" let g:indentLine_setConceal = 2
let g:indentLine_char_list = ['|', '¦', '┆', '┊']
" let g:indentLine_concealcursor = ""
let g:indentLine_fileTypeExclude = ['coc-explorer']

" {{{2 vista
let g:vista_default_executive = 'coc'
let g:vista_executive_for = {
    \ 'vimwiki': 'markdown',
    \ 'pandoc': 'markdown',
    \ 'markdown': 'toc',
    \ }

" {{{2 choosewin
let g:choosewin_overlay_enable = 1

" {{{2 coc.vim config

" {{{3 coc-settings.json
" alternative way to configure in vim script
" but don't use both at the same time
" help: coc#config()

" {{{4 coc explorer
call coc#config('explorer', {
      \ 'buffer.root.template': '[icon & 1] BUFFERS',
      \ 'file.root.template': '[icon & 1] PROJECT ([root]) [fullpath]',
      \ 'file.child.template': '[git | 2] [selection | clip | 1] [indent][icon | 1] [diagnosticError & 1][filename omitCenter 1][modified][readonly] [linkIcon & 1][link growRight 1 omitCenter 5]',
      \ 'file.showHiddenFiles': v:true,
      \ 'file.autoReveal': v:false,
      \ 'icon.enableVimDevicons': v:false,
      \ 'icon.enableNerdfont': v:false,
      \ 'previewAction.onHover': 'labeling',
      \ 'keyMappings.global': {
        \ 'v': 'open:vsplit',
        \ '<cr>': ['wait', 'expandable?', 'expanded?', 'collapse', 'expand', 'open'],
        \ 'cd': ['cd'],
        \ 'm': 'actionMenu',
        \ 'mc': 'copyFile',
        \ 'C': 'copyFile',
        \ 'md': 'delete',
        \ 'D': 'delete',
        \ 'H': ['wait', 'gotoParent'],
        \ 'L': ['cd']
        \ }
      \ })
" {{{4 coc lists
call coc#config('list.source.grep.args', ['--hidden', '--vimgrep', '--heading', '-S'])
call coc#config('session.directory', stdpath('data').'/session') " in startify autoload/startify.vim


" {{{3 coc-extension list
" coc-vetur: Vue.js
let g:coc_global_extensions = [
            \"coc-css",
            \"coc-cssmodules",
            \"coc-eslint",
            \"coc-explorer",
            \"coc-git",
            \"coc-go",
            \"coc-highlight",
            \"coc-json",
            \"coc-lists",
            \"coc-markdownlint",
            \"coc-prettier",
            \"coc-sh",
            \"coc-tabnine",
            \"coc-tsserver",
            \"coc-vetur",
            \"coc-vimlsp",
            \"coc-vimtex",
            \"coc-yaml",
            \"coc-yank"
            \]

" {{{3 coc settings and shortcuts
" TextEdit might fail if hidden is not set.
set hidden

" Having longer updatetime (default is 4000 ms = 4 s) leads to noticeable
" delays and poor user experience.
set updatetime=300

" Don't pass messages to |ins-completion-menu|.
set shortmess+=c

" Use tab for trigger completion with characters ahead and navigate.
" NOTE: Use command ':verbose imap <tab>' to make sure tab is not mapped by
" other plugin before putting this into your config.
inoremap <silent><expr> <TAB>
  \ pumvisible() ? "\<C-n>" :
  \ <SID>check_back_space() ? "\<TAB>" :
  \ coc#refresh()
inoremap <expr><S-TAB> pumvisible() ? "\<C-p>" : "\<C-h>"

function! s:check_back_space() abort
  let col = col('.') - 1
  return !col || getline('.')[col - 1]  =~# '\s'
endfunction

" Use <c-space> to trigger completion.
if has('nvim')
  inoremap <silent><expr> <c-space> coc#refresh()
else
  inoremap <silent><expr> <c-@> coc#refresh()
endif

function! s:check_back_space() abort
  let col = col('.') - 1
  return !col || getline('.')[col - 1]  =~# '\s'
endfunction

" Use <cr> to confirm completion, `<C-g>u` means break undo chain at current
" position. Coc only does snippet and additional edit on confirm.
" <cr> could be remapped by other vim plugin, try `:verbose imap <CR>`.
if exists('*complete_info')
  inoremap <expr> <cr> complete_info()["selected"] != "-1" ? "\<C-y>" : "\<C-g>u\<CR>"
else
  inoremap <expr> <cr> pumvisible() ? "\<C-y>" : "\<C-g>u\<CR>"
endif

" Make <CR> auto-select the first completion item and notify coc.nvim to
" format on enter, <cr> could be remapped by other vim plugin
inoremap <silent><expr> <cr> pumvisible() ? coc#_select_confirm()
                              \: "\<C-g>u\<CR>\<c-r>=coc#on_enter()\<CR>"

" Use `[g` and `]g` to navigate diagnostics
" Use `:CocDiagnostics` to get all diagnostics of current buffer in location list.
nmap <silent> [g <Plug>(coc-diagnostic-prev)
nmap <silent> ]g <Plug>(coc-diagnostic-next)

" GoTo code navigation.
nmap <silent> gd <Plug>(coc-definition)
nmap <silent> gy <Plug>(coc-type-definition)
nmap <silent> gi <Plug>(coc-implementation)
nmap <silent> gr <Plug>(coc-references)

" Use K to show documentation in preview window.
nnoremap <silent> K :call <SID>show_documentation()<CR>

function! s:show_documentation()
  if (index(['vim','help'], &filetype) >= 0)
    execute 'h '.expand('<cword>')
  elseif (coc#rpc#ready())
    call CocActionAsync('doHover')
  else
    execute '!' . &keywordprg . " " . expand('<cword>')
  endif
endfunction

" Highlight the symbol and its references when holding the cursor.
autocmd CursorHold * silent call CocActionAsync('highlight')

" Symbol renaming.
nmap <leader>rn <Plug>(coc-rename)

" Formatting selected code.
xmap <leader>f  <Plug>(coc-format-selected)
nmap <leader>f  <Plug>(coc-format-selected)

augroup mygroup
  autocmd!
  " Setup formatexpr specified filetype(s).
  autocmd FileType typescript,json setl formatexpr=CocAction('formatSelected')
  " Update signature help on jump placeholder.
  autocmd User CocJumpPlaceholder call CocActionAsync('showSignatureHelp')
augroup end

" Applying codeAction to the selected region.
" Example: `<leader>aap` for current paragraph
xmap <leader>a  <Plug>(coc-codeaction-selected)
nmap <leader>a  <Plug>(coc-codeaction-selected)

" Remap keys for applying codeAction to the current buffer.
nmap <leader>ac  <Plug>(coc-codeaction)
" Apply AutoFix to problem on the current line.
nmap <leader>qf  <Plug>(coc-fix-current)

" Map function and class text objects
" NOTE: Requires 'textDocument.documentSymbol' support from the language server.
xmap if <Plug>(coc-funcobj-i)
omap if <Plug>(coc-funcobj-i)
xmap af <Plug>(coc-funcobj-a)
omap af <Plug>(coc-funcobj-a)
xmap ic <Plug>(coc-classobj-i)
omap ic <Plug>(coc-classobj-i)
xmap ac <Plug>(coc-classobj-a)
omap ac <Plug>(coc-classobj-a)

if has('nvim-0.4.3') || has('patch-8.2.0750')
    nnoremap <nowait><expr> <C-f> coc#float#has_scroll() ? coc#float#scroll(1) : "\<C-f>"
    nnoremap <nowait><expr> <C-b> coc#float#has_scroll() ? coc#float#scroll(0) : "\<C-b>"
    inoremap <nowait><expr> <C-f> coc#float#has_scroll() ? "\<c-r>=coc#float#scroll(1)\<cr>" : "\<Right>"
    inoremap <nowait><expr> <C-b> coc#float#has_scroll() ? "\<c-r>=coc#float#scroll(0)\<cr>" : "\<Left>"
endif
" }}}
" {{{2 coc-explorer
function CocExplorerInited(filetype, bufnr)
  call setbufvar(a:bufnr, '&number', 1)
  call setbufvar(a:bufnr, '&relativenumber', 1)
endfunction

function! s:init_explorer()
  set winblend=10

  " Integration with other plugins

  " CocList
  nnoremap <buffer> <Leader>fg :call <SID>exec_cur_dir('CocList -I grep')<CR>
  nnoremap <buffer> <Leader>fG :call <SID>exec_cur_dir('CocList -I grep -regex')<CR>
  nnoremap <buffer> <C-p> :call <SID>exec_cur_dir('CocList files')<CR>

  " vim-floaterm
  nnoremap <buffer> <Leader>ft :call <SID>exec_cur_dir('FloatermNew --wintype=floating')<CR>
endfunction

augroup CocExplorerCustom
  autocmd!
  " autocmd BufEnter * call <SID>enter_explorer()
  autocmd FileType coc-explorer call <SID>init_explorer()
augroup END

" let g:coc_explorer_global_presets = {
"   \ 'workspace': {
"     \ 'root-uri': getcwd(),
"     \ },
"   \ }


" {{{2 suda
let g:suda_smart_edit = 1
" }}}

" }}}

" {{{1 Colors

set t_Co=256 " 开启 256颜色
if (has("termguicolors"))
  " 使用 RGB 颜色
  set termguicolors
endif
set termguicolors 
set background=dark
colorscheme onedark " iceberg

" }}}

" {{{1 Display Style
syntax enable

set fdm=syntax " 代码折叠 manual indent expr syntax diff marker
" set syntax=whitespace
" set list
set cursorline " highlight current line of cursor

set listchars=tab:▸\ ,trail:~,extends:>,precedes:<,space:␣ " ,eol:¬
set nu    " 显示行号 show line number
set rnu     " 相对行号 use relative line number

" gui font
if has("gui_running")
  if has("gui_gtk2") || has("gui_gtk3")
    set guifont=Courier\ New\ 11
  elseif has("gui_photon")
    set guifont=Courier\ New:s11
  elseif has("gui_kde")
    set guifont=Courier\ New/11/-1/5/50/0/0/0/1/0
  elseif has("x11")
    set guifont=-*-courier-medium-r-normal-*-*-180-*-*-m-*-*
  else
    set guifont=Courier_New:h11:cDEFAULT
  endif
endif
" detect os: https://vi.stackexchange.com/questions/2572/detect-os-in-vimscript
" if has('macunix')
"   set guifont=Monaco:h14:cANSI
" endif
" set guifont=Droid_Sans_Mono:h11:cANSI
" set guifontwide=WenQuanYi_Micro_Hei:h11:cANSI

set showcmd  " 显示输出的命令
" fillchars http://vimdoc.sourceforge.net/htmldoc/options.html#%27fillchars%27
set fillchars+=vert:│ " |(U+007C)│(U+2502)

" status line and command line
set laststatus=2  " 总是显示状态行
set cmdheight=1  " 命令行（在状态下）的高度


" }}}

" {{{1 Highlight Color
" consider reading doc from onedark plugin to change the highlight color
" }}}

" {{{1 Encodings
set fencs=utf-8,ucs-bom,shift-jis,gb18030,gbk,gb2312,cp936
set termencoding=utf-8
set encoding=utf-8
set fileencoding=utf-8
" }}}

" {{{1 Keyboard Mappings/Bindings & Shortcuts
" <leader>
let mapleader="\<space>"
" see help ttimeout
set notimeout
set ttimeout

" {{{2 plugins

" {{{3 fugitive
nnoremap <silent> <leader>G :G<CR>

" {{{3 choosewin
nmap - <Plug>(choosewin)

" {{{3 coc.nvim and coc-extensions
" {{{4 coc-explorer
nnoremap <silent> <leader>e :call CocAction('runCommand', 'explorer', getcwd(), '--toggle', '--quit-on-open')<CR>
" nnoremap <silent> <leader>e :CocCommand explorer --toggle --quit-on-open getcwd()<CR>
" {{{4 coc-lists
nnoremap <silent> <leader>l :<C-u>CocList <CR>
nnoremap <silent> <leader>y  :<C-u>CocList -A --normal yank<cr>
nnoremap <silent> <leader>lb :<C-u>CocList buffers<CR>
nnoremap <silent> <leader>ls :<C-u>CocList files<CR>
nnoremap <silent> <leader>lg :<C-u>CocList grep<CR>
nnoremap <silent> <leader>b :<C-u>CocList --normal buffers<CR>
" {{{4 coc action
" format code 格式化代码
vmap <leader>f  <Plug>(coc-format-selected)
nmap <leader>f  <Plug>(coc-format-selected)
" {{{3 vista
nnoremap <silent> <leader>g :Vista!!<CR>
" {{{3 tagbar
nnoremap <silent> <leader>gg :TagbarToggle<CR>
" {{{3 lf
nnoremap <silent> <leader>lf :Lf<CR>
" {{{3 maximizer
nnoremap <silent> <leader>z :MaximizerToggle<CR>

" {{{3 denite
"   ;         - Browser currently open buffers
"   <leader>pj - Browse list of files in current directory
"   <leader>s - Search current directory for occurences of given term and close window if no results
"   <leader>j - Search current directory for occurences of word under cursor
nnoremap ; :Denite buffer<CR>
nnoremap <leader>pj :DeniteProjectDir file/rec<CR>
nnoremap <leader>s :<C-u>Denite grep:. -no-empty<CR>
nnoremap <leader>sf :<C-u>Denite file/rec<CR>
nnoremap <leader>j :<C-u>DeniteCursorWord grep:.<CR>

" Define mappings while in 'filter' mode
"   <C-o>         - Switch to normal mode inside of search results
"   <C-q>         - Quit Denite window
"   <Esc>         - Exit denite window in any mode
"   <CR>          - Open currently selected file in any mode
"   <C-t>         - Open currently selected file in a new tab
"   <C-v>         - Open currently selected file a vertical split
"   <C-h>         - Open currently selected file in a horizontal split
"   <C-j>         - Move cursor to the next candidate
"   <C-k>         - Move cursor to the previous candidate
autocmd FileType denite-filter call s:denite_filter_my_settings()
function! s:denite_filter_my_settings() abort
  inoremap <silent><buffer> <C-o>
  \ <Esc><C-w>p
  inoremap <silent><buffer><expr> <C-q>
  \ denite#do_map('quit')
  inoremap <silent><buffer><expr> <CR>
  \ denite#do_map('do_action')
  inoremap <silent><buffer><expr> <C-t>
  \ denite#do_map('do_action', 'tabopen')
  inoremap <silent><buffer><expr> <C-v>
  \ denite#do_map('do_action', 'vsplit')
  inoremap <silent><buffer><expr> <C-h>
  \ denite#do_map('do_action', 'split')
  inoremap <silent><buffer> <C-j>
  \ <Esc><C-w>p:call cursor(line('.')+1,0)<CR><C-w>pA
  inoremap <silent><buffer> <C-k>
  \ <Esc><C-w>p:call cursor(line('.')-1,0)<CR><C-w>pA
endfunction

" Define mappings while in denite window
"   <CR>        - Opens currently selected file
"   q or <Esc>  - Quit Denite window
"   d           - Delete currenly selected file
"   p           - Preview currently selected file
"   <C-o> or i  - Switch to insert mode inside of filter prompt
"   <C-t>       - Open currently selected file in a new tab
"   <C-v>       - Open currently selected file a vertical split
"   <C-h>       - Open currently selected file in a horizontal split
autocmd FileType denite call s:denite_my_settings()
function! s:denite_my_settings() abort
  nnoremap <silent><buffer><expr> <CR>
  \ denite#do_map('do_action')
  nnoremap <silent><buffer><expr> d
  \ denite#do_map('do_action', 'delete')
  nnoremap <silent><buffer><expr> p
  \ denite#do_map('do_action', 'preview')
  nnoremap <silent><buffer><expr> q
  \ denite#do_map('quit')
  nnoremap <silent><buffer><expr> <Esc>
  \ denite#do_map('quit')
  nnoremap <silent><buffer><expr> i
  \ denite#do_map('open_filter_buffer')
  nnoremap <silent><buffer><expr> <C-o>
  \ denite#do_map('open_filter_buffer')
  nnoremap <silent><buffer><expr> <C-t>
  \ denite#do_map('do_action', 'tabopen')
  nnoremap <silent><buffer><expr> <C-v>
  \ denite#do_map('do_action', 'vsplit')
  nnoremap <silent><buffer><expr> <C-h>
  \ denite#do_map('do_action', 'split')
  nnoremap <silent><buffer><expr> <Space>
  \ denite#do_map('toggle_select').'j'
endfunction

" {{{3 easy motion
let g:EasyMotion_do_mapping = 0 " Disable default mappings

" Jump to anywhere you want with minimal keystrokes, with just one key binding.
" `s{char}{label}`
" nmap s <Plug>(easymotion-overwin-f)
" or
" `s{char}{char}{label}`
" Need one more keystroke, but on average, it may be more comfortable.
nmap s <Plug>(easymotion-overwin-f2)

" Turn on case-insensitive feature
let g:EasyMotion_smartcase = 1

" JK motions: Line motions
" map <Leader>j <Plug>(easymotion-j)
" map <Leader>k <Plug>(easymotion-k)
" }}}

" {{{2 others
" sudo save file
cnoremap w!! w !sudo tee > /dev/null %

nnoremap <leader>w :w<CR>
nnoremap <silent> <leader>q :q<CR>
nnoremap <silent> <leader>t :tabnew<CR>
nnoremap <silent> <leader>p :set invpaste<CR>

nnoremap <C-N> :bnext<CR>
nnoremap <C-P> :bprev<CR>

noremap <F5> :set list!<CR>
inoremap <F5> <C-o>:set list!<CR>
cnoremap <F5> <C-c>:set list!<CR>

" }}}

" {{{1 Indent 缩进

filetype plugin indent on    " 必须 加载vim自带和插件相应的语法和文件类型相关脚本
" 忽视插件改变缩进,可以使用以下替代:
"filetype plugin on

set tabstop=2
set softtabstop=2
set shiftwidth=2
" set noexpandtab  " 不要用空格代替Tab
set expandtab
set smarttab  " 在行和段开始处使用制表符
set smartindent

" {{{1 Filetype Settings
" au FileType javascript,json setlocal shiftwidth=2 softtabstop=2 expandtab

" {{{1 Others
set history=1000  " 历史记录数
set undofile " save undo history
" do not save empty windows in vim sessions
set ssop-=blank " sessionoptions

" autocmd BufWritePost $MYVIMRC source $MYVIMRC " 配置立即生效

set splitbelow
set splitright

" {{{1 Load Local Configuration
" load local vim config file `.config/nvim/customize.vim`
let customize_file=expand(stdpath('config') . '/customize.vim')
if filereadable(customize_file)
  exec ':source ' . customize_file
endif
