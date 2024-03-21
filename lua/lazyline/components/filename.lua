local M = {}
function M.new(v)
    local actual = require('lazyline.components').mergeCapabilities(v, {
        events = { "BufEnter" },
        fmt = require('lazyline.components').pad,
    })
    local ret = actual
    ret[1] = function()
        local filename = vim.fn.expand("%")
        local split = vim.fn.split(filename, "/")


        return split[#split]
    end
    return ret
end

return M
