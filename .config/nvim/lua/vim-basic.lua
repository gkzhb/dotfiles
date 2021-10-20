-- vim: set fdm=marker:
-- {{{1 basic vim config
-- {{{2 set colorscheme
if vim.fn.has('termguicolors') then
  vim.opt.termguicolors=true
end
vim.opt.background = 'dark'
vim.g.colors_name = 'onedark'

-- {{{2 display
-- fillchars http://vimdoc.sourceforge.net/htmldoc/options.html#%27fillchars%27
vim.opt.fillchars = { vert = '│', fold = '·' }
vim.opt.listchars = {
  tab = '▸ ',
  trail = '~',
  extends = '>',
  precedes = '<',
  space = '␣',
  eol = '¬'
}
vim.opt.laststatus=2
vim.opt.cmdheight=1
vim.opt.showmode=false

vim.opt.cursorline=true
-- line number
vim.opt.nu=true
vim.opt.rnu=true
-- enable syntax
vim.cmd([[ syntax enable ]])


-- {{{2 file encoding
vim.opt.fencs={ 'utf-8', 'ucs-bom', 'shift-jis', 'gb18030', 'gbk', 'gb2312', 'cp936' }
vim.opt.encoding='utf-8'
vim.opt.fileencoding='utf-8'

-- {{{2 edit
vim.opt.hidden=true
-- {{{2 diff
vim.opt.diffopt = { algorithm = 'patience' }
-- {{{2 others
vim.opt.history=1000  -- 历史记录数
vim.opt.undofile=true -- save undo history
-- do not save empty windows in vim sessions
vim.opt.ssop:remove('blank') -- sessionoptions
vim.opt.scrolloff = 5

-- autocmd BufWritePost $MYVIMRC source $MYVIMRC -- 配置立即生效

vim.opt.splitbelow=true
vim.opt.splitright=true

-- {{{2 indent
vim.cmd([[ filetype plugin indent on]])
vim.opt.tabstop=2
vim.opt.softtabstop=2
vim.opt.shiftwidth=2
vim.opt.expandtab=true
vim.opt.smarttab=true  -- 在行和段开始处使用制表符
vim.opt.smartindent=true

-- {{{2 folding
vim.opt.foldlevelstart = 0

