" vim: set fdm=marker: 

" Plugin Settings
set nocompatible  "去掉讨厌的有关vi一致性模式，避免以前版本的一些bug和局限
filetype off

" {{{1 Plugins
call plug#begin()

" color theme
" Plug 'altercation/vim-colors-solarized'
" let g:solarized_termtrans=1
Plug 'cocopon/iceberg.vim'

" 显示颜色
Plug 'rrethy/vim-hexokinase', { 'do': 'make hexokinase' }
" let g:Hexokinase_highlighters = ['foreground']
" Filetype specific patterns to match
" entry value must be comma seperated list
let g:Hexokinase_ftOptInPatterns = {
    \ 'css': 'full_hex,rgb,rgba,hsl,hsla,colour_names',
    \ 'html': 'full_hex,rgb,rgba,hsl,hsla,colour_names',
    \ 'vim': 'full_hex,rgb,colour_names'
  \ }
" 方便编辑颜色
Plug 'Rykka/colorv.vim'
" needed for fetching schemes online.
Plug 'mattn/webapi-vim' " colorv 依赖

Plug 'christoomey/vim-tmux-navigator'
" Disable tmux navigator when zooming the Vim pane
let g:tmux_navigator_disable_when_zoomed = 1

" Plug 'ap/vim-buftabline'
Plug 'mzlogin/vim-markdown-toc'
" Markdown TOC 生成 https://mazhuang.org/2015/12/19/vim-markdown-toc/
" :GenTocGFM 在光标处生成 GFM 风格的 Table of Contents
" :RemoveToc 删除插件生成的 TOC

" statusline
Plug 'itchyny/lightline.vim'

" ts js
Plug 'leafgarland/typescript-vim'
Plug 'peitalin/vim-jsx-typescript'
Plug 'lukaszb/vim-web-indent'
" let g:js_indent = '/location/to/javascript.vim'


Plug 'majutsushi/tagbar'
Plug 'szw/vim-maximizer' " 最大化窗口
" Plugin 'lvht/tagbar-markdown'
Plug 'easymotion/vim-easymotion' " 移动光标

Plug 'lervag/vimtex'
Plug 'glacambre/firenvim', { 'do': { _ -> firenvim#install(0) } } " 浏览器插件
Plug 'mhinz/vim-startify' " start screen 启动屏
Plug 'ptzz/lf.vim' " lf 插件
Plug 'voldikss/vim-floaterm'
let g:lf_map_keys = 0
let g:lf_replace_netrw = 1 " Open lf when vim opens a directory

Plug 'neoclide/coc.nvim', {'branch': 'release'}
Plug 'mhinz/vim-signify' " VCS 文件修改情况显示

" git related
Plug 'tpope/vim-fugitive' " vim 中使用 git 的增强插件
Plug 'junegunn/gv.vim' " git commit browser
Plug 'sodapopcan/vim-twiggy' " git branch push/pull/rebase

Plug 'liuchengxu/vista.vim' " 

Plug 'markonm/traces.vim' " 实时预览命令替换
Plug 'tpope/vim-commentary' " 注释
" 缩进线条
Plug 'Yggdroot/indentLine'
let g:indentLine_enabled = 1
" let g:indentLine_showFirstIndentLevel = 1
" let g:indentLine_setColors = 0
" let g:indentLine_setConceal = 0
let g:indentLine_char_list = ['|', '¦', '┆', '┊']


" Plug 'leafOfTree/vim-vue-plugin' " vue

" {{{2 coc extensions
""""""""""""""""
" coc extensions
""""""""""""""""
Plug 'neoclide/coc-lists', {'do': 'yarn install --frozen-lockfile'}
Plug 'neoclide/coc-tabnine', {'do': 'yarn install --frozen-lockfile'}
Plug 'neoclide/coc-prettier', {'do': 'yarn install --frozen-lockfile'}
Plug 'weirongxu/coc-explorer', {'do': 'yarn install --frozen-lockfile'}
Plug 'neoclide/coc-eslint', {'do': 'yarn install --frozen-lockfile'}
Plug 'neoclide/coc-highlight', {'do': 'yarn install --frozen-lockfile'}
Plug 'neoclide/coc-yank', {'do': 'yarn install --frozen-lockfile'}

" language
Plug 'neoclide/coc-yaml', {'do': 'yarn install --frozen-lockfile'}
Plug 'neoclide/coc-json', {'do': 'yarn install --frozen-lockfile'}
Plug 'neoclide/coc-css', {'do': 'yarn install --frozen-lockfile'}
Plug 'antonk52/coc-cssmodules', {'do': 'yarn install --frozen-lockfile'}
Plug 'iamcco/coc-vimlsp', {'do': 'yarn install --frozen-lockfile'}
Plug 'neoclide/coc-tsserver', {'do': 'yarn install --frozen-lockfile'}
Plug 'josa42/coc-go', {'do': 'yarn install --frozen-lockfile'}
Plug 'neoclide/coc-vetur', {'do': 'yarn install --frozen-lockfile'} " vue
Plug 'fannheyward/coc-markdownlint', {'do': 'yarn install --frozen-lockfile'}
Plug 'josa42/coc-sh', {'do': 'yarn install --frozen-lockfile'}

" }}}


" 你的所有插件需要在下面这行之前
call plug#end()
" }}}

" {{{1 Plugin Configure

" {{{2 vim tex
" let g:vimtex_compiler_latexmk = {}
" let g:vimtex_imaps_leader = '@'
let g:tex_flavor = 'latex'
" }}}


filetype plugin indent on    " 必须 加载vim自带和插件相应的语法和文件类型相关脚本
" 忽视插件改变缩进,可以使用以下替代:
"filetype plugin on

" au VimEnter * silent NERDTree " 启动时自动开启 NERDTree (autocmd == au)
" from
" https://stackoverflow.com/questions/29973424/open-nerdtree-when-vim-is-opened-without-args-but-not-with
" autocmd StdinReadPre * let g:isReadingFromStdin = 1
" autocmd VimEnter * if !argc() && !exists('g:isReadingFromStdin') | NERDTree | endif

" let g:vista_icon_indent = ["a ", "b "]

" {{{2 coc.vim config
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
" }}}

" }}}

" {{{1 Colors

set t_Co=256 " 开启 256颜色
set termguicolors " 使用 RGB 颜色
set background=dark
colorscheme iceberg " solarized

" }}}


" {{{1 display style
syntax enable

set fdm=syntax " 代码折叠 manual indent expr syntax diff marker
" set syntax=whitespace
" set list

set listchars=tab:▸\ ,trail:~,extends:>,precedes:<,space:␣ " ,eol:¬
set nu		" 显示行号 show line number
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
" set font size for firenvim
" detect os: https://vi.stackexchange.com/questions/2572/detect-os-in-vimscript
if has('macunix')
    set guifont=Monaco:h14:cANSI
endif
" set guifont=Droid_Sans_Mono:h11:cANSI
" set guifontwide=WenQuanYi_Micro_Hei:h11:cANSI

set showcmd	" 显示输出的命令
" fillchars http://vimdoc.sourceforge.net/htmldoc/options.html#%27fillchars%27
set fillchars+=vert:│ " |(U+007C)│(U+2502)

" status line and command line
set laststatus=2	" 总是显示状态行
set cmdheight=1	" 命令行（在状态下）的高度


" }}}

" {{{1 Highlight Color

" hi StatusLine cterm=bold ctermbg=238 ctermfg=11
" hi StatusLineNC cterm=NONE ctermbg=238 ctermfg=NONE
""""""" CursorLine Color
" https://stackoverflow.com/questions/8247243/highlighting-the-current-line-number-in-vim
hi clear CursorLine
hi CursorLine cterm=NONE ctermbg=238 ctermfg=NONE
hi CursorLineNR cterm=bold ctermbg=238 ctermfg=226
hi LineNR ctermbg=236
set cursorline
""""""" VertSplit Color
hi VertSplit cterm=reverse ctermbg=243 ctermfg=236
""""""" Tab Color
" hi TabLine cterm=NONE ctermfg=229 ctermbg=237 " Buffer not currently visible
" hi TabLineSel cterm=bold ctermfg=253 ctermbg=238 " Buffer shown in current window
" hi TabLineFill cterm=NONE ctermbg=237 " Empty area
" hi PmenuSel cterm=NONE ctermfg=229 ctermbg=240 " Buffer shown in other window

" }}}

" {{{1 Status Line

set noshowmode " 隐藏最下方显示当前模式

let g:lightline = {
      \ 'colorscheme': 'iceberg',
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
        \ 'fileencoding': '%{toupper(&fenc!=#""?&fenc:&enc)}',
        \ 'fileformat': '%{toupper(&ff)}',
        \ 'filetype': '%{&ft!=#""?&ft:"none"}'
        \ },
      \ 'component_function': {
        \ 'cocstatus': 'StatusDiagnostic',
        \ 'gitbranch': 'FugitiveHead',
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
" let s:p.normal = {
"       \ 'left': [[ ]]
"       \ }

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

" }}}

" {{{1 Encodings
set fencs=utf-8,ucs-bom,shift-jis,gb18030,gbk,gb2312,cp936
set termencoding=utf-8
set encoding=utf-8
" set fileencodings=ucs-bom,utf-8,cp936
set fileencoding=utf-8
" }}}


set history=1000	" 历史记录数

" autocmd BufWritePost $MYVIMRC source $MYVIMRC " 配置立即生效

set splitbelow
set splitright

" To prevent conceal in LaTeX files
let g:tex_conceal = ''
" To prevent conceal in any file
set conceallevel=0

" {{{1 keyboard mappings/bindings & shortcuts
" <leader>
let mapleader=" "

" {{{2 Plugins
nmap <silent> <leader>e :CocCommand explorer --toggle<CR>
nnoremap <silent> <leader>y  :<C-u>CocList -A --normal yank<cr>
nmap <leader>g :Vista coc<CR>
nmap <leader>gg :TagbarToggle<CR>
nmap <silent> <leader>z :MaximizerToggle<CR>
nmap <silent> <leader>lf :Lf<CR>
" format code 格式化代码
vmap <leader>f  <Plug>(coc-format-selected)
nmap <leader>f  <Plug>(coc-format-selected)


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
map <Leader>j <Plug>(easymotion-j)
map <Leader>k <Plug>(easymotion-k)
" }}}

" }}}

nmap <leader>w :w<CR>
nmap <leader>q :q<CR>
nmap <silent> <leader>t :tabnew<CR>
nmap <silent> <leader>p :set invpaste<CR>
nmap <leader>b :ls<CR>:b<Space>
nnoremap <Leader>c :set cursorline! cursorcolumn!<CR>

nnoremap <C-N> :bnext<CR>
nnoremap <C-P> :bprev<CR>

noremap <F5> :set list!<CR>
inoremap <F5> <C-o>:set list!<CR>
cnoremap <F5> <C-c>:set list!<CR>

" }}}


" {{{1 indent 缩进
set tabstop=4
set softtabstop=4
set shiftwidth=4
" set noexpandtab	" 不要用空格代替Tab
set expandtab
set smarttab	" 在行和段开始处使用制表符
set smartindent


au BufEnter,BufNew *.php :set filetype=javascript
au BufEnter,BufNew *.fish :set filetype=sh
au BufEnter,BufNew Jenkinsfile :set filetype=groovy

au FileType groovy setlocal expandtab tabstop=2 shiftwidth=2 autoindent smartindent
au FileType python setlocal expandtab tabstop=4 shiftwidth=4
au FileType html setlocal shiftwidth=2 softtabstop=2 expandtab
au FileType javascript,json setlocal shiftwidth=2 softtabstop=2 expandtab
au FileType typescript,typescriptreact,less setlocal shiftwidth=4 softtabstop=4 expandtab
au FileType vue setlocal expandtab
" au Filetype json let g:indentLine_setConceal = 2
