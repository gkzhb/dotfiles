local keymap = vim.keymap.set
local opts = { noremap = true, silent = true }

--- Call VSCode command
local function vsc_action(cmd)
     return string.format("<cmd>lua require'vscode'.action('%s')<CR>", cmd)
end
-- remap leader key
keymap("n", "<Space>", "", opts)
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- configs
vim.o.cmdheight = 1
vim.o.timeoutlen = 500
vim.o.ttimeout = true

-- clipboard related
-- yank to system clipboard
keymap({"n", "v"}, "<leader>y", '"+y', opts)
-- paste from system clipboard
keymap({"n", "v"}, "<leader>p", '"+p', opts)

-- call vscode commands from neovim

-- general keymaps
keymap({"n", "v"}, "<leader>nc", vsc_action('notifications.clearAll'))

-- buffer related commands
-- save file
keymap({"n"}, "<leader>bs", vsc_action('workbench.action.files.save'))
-- switch to buffer
keymap({"n"}, "<leader>bb", vsc_action('workbench.action.openPreviousEditorFromHistory'))
-- format file
keymap({"n", "v"}, "<leader>bf", vsc_action('editor.action.formatDocument'))

-- search related
-- search content across project
keymap({"n"}, "<leader>sg", vsc_action('workbench.action.quickTextSearch'))
-- search file by file name
keymap({"n", "v"}, "<leader>sf", vsc_action('workbench.action.quickOpen'))
-- search vsc commands
keymap({"n", "v"}, "<leader>sv", vsc_action('workbench.action.showCommands'))

-- toggle or open something
-- open terminal
keymap({"n", "v"}, "<leader>ot", vsc_action('workbench.action.terminal.toggleTerminal'))
-- toggle bottom panel
keymap({"n", "v"}, "<leader>ob", vsc_action('workbench.action.togglePanel'))
-- toggle breakpoint
keymap({"n", "v"}, "<leader>odb", vsc_action('editor.debug.action.toggleBreakpoint'))
-- toggle problems tab
keymap({"n", "v"}, "<leader>od", vsc_action('workbench.actions.view.problems'))
-- toggle search highlight
keymap({"n", "v"}, "<leader>th", '<cmd>:nohl<CR>')
keymap({"n", "v"}, "<leader>ts", vsc_action('workbench.action.toggleSidebarVisibility'))
keymap({"n", "v"}, "<leader>d", vsc_action('workbench.view.explorer'))
keymap({"n", "v"}, "<leader>fh", vsc_action('workbench.action.focusSideBar'))
-- toggle zen mode
keymap({"n"}, "<leader>oz", vsc_action('workbench.action.toggleZenMode'))


-- code actions
-- show hover info
keymap({"n", "v"}, "K", vsc_action('editor.action.showHover'))
-- open quick fix list
keymap({"n", "v"}, "<leader>ac", vsc_action('editor.action.quickFix'))
-- rename symbol
keymap({"n", "v"}, "<leader>ar", vsc_action('editor.action.rename'))
keymap({"n", "v"}, "gr", vsc_action('editor.action.goToReferences'))
keymap({"n", "v"}, "<leader>gr", vsc_action('references-view.findReferences'))
keymap({"n", "v"}, "]e", vsc_action('editor.action.marker.next'))
keymap({"n", "v"}, "[e", vsc_action('editor.action.marker.prev'))
-- toggle fold
keymap({"n"}, "zi", vsc_action('editor.toggleFold'))
keymap({"n"}, "zc", vsc_action('editor.fold'))
keymap({"n"}, "zo", vsc_action('editor.unfold'))

-- git related
keymap({"n", "v"}, "<leader>gb", vsc_action('gitlens.toggleFileBlame'))
keymap({"n", "v"}, "<leader>gg", vsc_action('workbench.scm.focus'))



-- project related
-- run actions
keymap({"n", "v"}, "<leader>pr", vsc_action('code-runner.run'))