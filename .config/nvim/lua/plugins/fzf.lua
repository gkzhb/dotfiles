local M = {}

function M.init()
  local actions = require("fzf-lua").actions
  require('fzf-lua').setup{
    keymap = {
      builtin = {
        true,
      },
      fzf = {
        true,
        ['ctrl-a'] = 'toggle-all',
      },
    },
    actions = {
      files = {
        ["enter"]       = actions.file_edit_or_qf,
        ["ctrl-s"]      = actions.file_split,
        ["ctrl-v"]      = actions.file_vsplit,
        ["ctrl-t"]      = actions.file_tabedit,
        ["ctrl-q"]       = actions.file_sel_to_qf,
        ["ctrl-alt-l"]       = actions.file_sel_to_ll,
        ["alt-i"]       = actions.toggle_ignore,
        ["alt-h"]       = actions.toggle_hidden,
        ["alt-f"]       = actions.toggle_follow,
      }
    }
  }
end

return M
