local M = {}

function M.new(opts)
    local actual = require('lazyline.components').mergeCapabilities(opts, {
        events = { "CursorMoved", "BufEnter" },
        fmt = require('lazyline.components').pad,
    })
    local ret = actual
    ret[1] = function()
        local percent = vim.fn.line('.') / vim.fn.line('$') * 100
        return string.format("%3d%%%%", percent)
    end
    return ret
end

return M
