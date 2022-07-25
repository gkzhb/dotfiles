local M = {}
-- Ref: https://github.com/AdamWagner/stackline/issues/42#issuecomment-696817874
function _G.CreaseIndent()
  local fs = vim.fn.nextnonblank(vim.v.foldstart)
  local line = string.gsub(vim.fn.getline(fs), '\t', string.rep(' ', vim.o.tabstop))
  return string.match(line, '%s*')
end

function _G.CreaseHashtagIndent()
  return string.rep('#', vim.v.foldlevel)
end

function _G.CreaseFoldContent()
  local text = vim.fn.foldtext()
  local startIdx = string.find(text, ':')
  return text:sub(startIdx + 2)
end

function _G.CreaseLineInfo()
  local width = (vim.g.numberwidth or 4) - 1
  local strTemplate = string.format('%%%du -- %%%du : %%%du lines  ', width, width, width)
  return string.format(strTemplate, vim.v.foldstart, vim.v.foldend, vim.v.foldend - vim.v.foldstart + 1)
end

function M.init()
  vim.g.crease_foldtext = {
    default = '%{v:lua.CreaseIndent()}%{v:lua.CreaseFoldContent()} ···  %=  %{v:lua.CreaseLineInfo()}%f%f%f%f',
    marker = '%{v:lua.CreaseIndent()}%{v:lua.CreaseHashtagIndent()} %{v:lua.CreaseFoldContent()}  %=  %{v:lua.CreaseLineInfo()}%f%f%f%f',
  }
end
return M
