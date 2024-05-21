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


        local name = split[#split]
        split = vim.fn.split(name, '\\')
        name = split[#split]
        if name == "" or name == nil then
            name = "[No Name]"
        end
        return name
    end
    return ret
end

return M
