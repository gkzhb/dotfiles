-- vim: set fdm=marker:
-- {{{1 basic vim config
-- {{{2 set colorscheme
vim.opt.termguicolors = true
vim.opt.background = 'dark'
-- vim.g.colors_name = 'onedark' -- onedarkpro

-- {{{2 display
-- fillchars http://vimdoc.sourceforge.net/htmldoc/options.html#%27fillchars%27
vim.opt.fillchars = { vert = '│', fold = '·' }
vim.opt.list = true
vim.opt.listchars = {
  tab = '▸ ',
  trail = '~',
  extends = '>',
  precedes = '<',
  lead = '⋅',
}
vim.opt.laststatus = 2
vim.opt.cmdheight = 1
vim.opt.showmode = false

vim.opt.cursorline = true
-- line number
vim.opt.nu = true
vim.opt.rnu = true
vim.wo.signcolumn = 'auto'
-- enable syntax
vim.cmd([[ syntax enable ]])

-- {{{2 tabpage
-- always show tabline
vim.opt.showtabline = 2

-- {{{2 file encoding
vim.opt.fencs = { 'utf-8', 'ucs-bom', 'shift-jis', 'gb18030', 'gbk', 'gb2312', 'cp936' }
vim.opt.encoding = 'utf-8'
vim.opt.fileencoding = 'utf-8'

-- {{{2 edit
vim.opt.hidden = true
-- {{{2 diff
vim.opt.diffopt = { algorithm = 'patience' }
if vim.fn.has('nvim-0.9') then
  -- linematch: new feature since nvim 0.9
  vim.opt.diffopt = { algorithm = 'patience', linematch = 300 }
else
  vim.opt.diffopt = { algorithm = 'patience' }
end

-- {{{2 indent
vim.cmd([[ filetype plugin indent on]])
vim.opt.tabstop = 2
vim.opt.softtabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true
vim.opt.smarttab = true
vim.opt.smartindent = true

-- {{{2 folding
vim.opt.foldlevelstart = 0
vim.opt.foldlevel = 99

-- {{{2 others
vim.opt.history = 1000 -- save history
vim.opt.undofile = true -- save undo history
-- do not save empty windows in vim sessions
vim.opt.ssop:remove('blank') -- sessionoptions
vim.opt.ssop:append({ 'tabpages', 'globals' }) -- from tabline.nvim
vim.opt.scrolloff = 5

vim.opt.splitbelow = true
vim.opt.splitright = true

vim.opt.updatetime = 300 -- CursorHold delay
vim.opt.shortmess:append({ c = true })
vim.g.loaded_matchparen = 1 -- do not load vim built-in matchparen plugin
vim.opt.mouse = ''

-- enable lua-loader to improve performance
vim.loader.enable()
-- }}}

-- {{{1 check and install packer
local utils = require('utils')
local pckr = utils.loadModuleSafely('utils.packer')
if pckr then
  pckr.init()
end
-- }}}
