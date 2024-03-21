local M = {}
function M.new(v)
    local actual = require('lazyline.components').mergeCapabilities(v, {
        events = { "CursorMoved" },
        fmt = require('lazyline.components').pad,
    })
    local ret = actual
    ret[1] = function()
        local c = vim.api.nvim_win_get_cursor(0)

        local r = c[1] .. ":" .. c[2]
        if #r < 6 then
            r = r .. string.rep(" ", 6 - #r)
        end
        return r
    end
    return ret
end

return M
