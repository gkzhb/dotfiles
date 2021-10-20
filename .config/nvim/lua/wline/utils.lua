local M = {}
local vim_components = require('windline.components.vim')

function M.searchCount()
    return function()
        local searchCount = vim_components.search_count()()
        if searchCount ~= '' then
            return ' ' .. searchCount
        else
            return ''
        end
    end
end

function M.format(opt)
    return function()
        if opt.value and opt.value ~= 0 then
            return string.format(opt.format or '%s', opt.value)
        else
            return ''
        end
    end
end

function M.fileModified()
end

return M
