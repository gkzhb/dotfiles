local M = {}

function M.init()
  local onedarkpro = require('onedarkpro')
  onedarkpro.setup({
    theme = 'onedark',
    options = {
      terminal_colors = false,
      transparency = true,
      cursorline = true,
      window_unfocussed_color = true,
    },
    hlgroups = {
      TSVariable = { fg = '${white}' },
      TSProperty = { fg = '${cyan}' },
      NormalFloat = { bg = '#282c34', fg = '${white}'},
      CocFadeOut = { bg = '#282c34' },
    },
  })
  onedarkpro.load()
end

return M
