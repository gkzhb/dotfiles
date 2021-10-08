local M = {}
function M.init()
  if vim.g.started_by_firenvim then
    -- set font size for firenvim
    if vim.fn.has('macunix') then
      vim.opt.guifont = 'Monaco:h20:cANSI'
    elseif vim.fn.has('unix') then
      vim.opt.guifont = 'Courier New 11:h10'
    end
  end
end
return M
