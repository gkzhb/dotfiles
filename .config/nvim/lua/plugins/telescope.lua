local M = {}

function M.init()
  require('telescope').setup({
    defaults = {
      mappings = {
        i = {
          ['C-q'] = require('telescope.actions').close,
        },
        n = {
          ['q'] = require('telescope.actions').close,
        },
      },
    },
    extensions = {
      tele_tabby = {
        use_highlight = true,
      },
    },
  })
end

return M
