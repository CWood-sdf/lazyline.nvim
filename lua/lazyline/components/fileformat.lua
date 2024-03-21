local M = {}
local symbols = {
    unix = '', -- e712
    dos = '', -- e70f
    mac = '', -- e711
}

function M.new(v)
    local actual = require('lazyline.components').mergeCapabilities(v, {
        symbols = symbols,
        -- fmt = require('lazyline.components').pad,
    })
    local ret = actual
    ret[1] = function()
        local format = vim.bo.fileformat
        if actual.icons_enabled then
            return symbols[format]
        else
            return format
        end
    end
    return ret
end

return M
