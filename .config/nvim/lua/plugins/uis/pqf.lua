-- 快速修复列表美化
local M = {
  'https://gitlab.com/yorickpeterse/nvim-pqf.git',
}

function M.config()
  require('pqf').setup()
end

return M
