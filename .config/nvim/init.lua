-- vim: set fdm=marker: 
-- {{{1 predefined variables
-- predefine function
local map = vim.api.nvim_set_keymap

-- {{{1 check packer installation
local packerPath = vim.fn.stdpath('data') .. '/site/pack/packer/start/packer.nvim'
if vim.fn.empty(vim.fn.glob(packerPath)) > 0 then
  vim.api.nvim_echo({{'Installing packer.nvim', 'Type'}}, true, {})
  local packerGitUrl = 'https://github.com/wbthomason/packer.nvim'
  local installPackerCmd = string.format('10split |term git clone --depth=1 %s %s', packerGitUrl, packerPath)
  vim.api.nvim_command(installPackerCmd)
end

-- load packer plugins
require('plugins')
-- }}}
-- {{{1 set config
-- {{{2 set colorscheme
if vim.fn.has('termguicolors') then
  vim.opt.termguicolors=true
end
vim.opt.background = 'dark'
vim.g.colors_name = 'onedark'

-- {{{2 display
-- fillchars http://vimdoc.sourceforge.net/htmldoc/options.html#%27fillchars%27
vim.opt.fillchars:append({ vert = '│', fold = '·' })
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

-- {{{1 plugin configuration
-- Plugins are in 'lua/plugins/init.lua'
-- {{{2 vim tmux navigator
-- Disable tmux navigator when zooming the Vim pane
vim.g.tmux_navigator_disable_when_zoomed = 1

-- {{{2 startify
-- session directory, default to `$XDG_DATA_HOME/nvim/session`
-- should be the same as Coc Session 'session.directory' in coc-settings.json
--
-- vim.g.startify_session_dir = '$XDG_DATA_HOME/nvim/session'
-- do not change cwd when opening files
vim.g.startify_change_to_dir = 0
vim.g.startify_change_to_vcs_root = 0

-- {{{2 lf

-- {{{2 denite TODO }}}
-- {{{2 indent line
vim.g.indentLine_enabled = 1
-- let g:indentLine_showFirstIndentLevel = 1
-- let g:indentLine_setColors = 0
-- let g:indentLine_setConceal = 2
vim.g.indentLine_char_list = {'|', '¦', '┆', '┊'}
-- let g:indentLine_concealcursor = ""
vim.g.indentLine_fileTypeExclude = {'coc-explorer'}
-- {{{1 Keyboard Mappings/Bindings & Shortcuts

local mappings = require('mappings')
mappings.init()
mappings.setMappings()

-- {{{2 others

-- {{{1 Load Local Configuration
-- load local vim config file `.config/nvim/customize.vim`
local customizeFile = vim.fn.expand(vim.fn.stdpath('config') .. '/customize.lua')
if vim.fn.filereadable(customizeFile) > 0 then
  vim.cmd('source ' .. customizeFile)
end
