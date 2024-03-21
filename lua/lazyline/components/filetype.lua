local M = {}

function M.new(v)
    local actual = require('lazyline.components').mergeCapabilities(v, {
        events = { "BufEnter" },
        fmt = require('lazyline.components').pad,
        icon_only = true,
        icon = {
            align = "left",
        },
    })
    local ret = actual
    ret[1] = function()
        local ft = vim.bo.filetype or ""
        local hasDevIcons, devicons = pcall(require, "nvim-web-devicons")
        local icon, iconhl = nil, nil
        if hasDevIcons then
            icon, iconhl = devicons.get_icon(ft, vim.fn.expand("%:t"))
            if icon == nil then
                icon, iconhl = devicons.get_icon_by_filetype(vim.bo.filetype)
            end
            if icon == nil or iconhl == nil then
                iconhl = "DevIconDefault"
                icon = ""
            end
            if icon then
                icon = icon .. " "
            end
        end
        if iconhl then
            icon = "%#" .. iconhl .. "#" .. icon .. "%*"
        end
        if actual.icon_only then
            return icon
        else
            if actual.icon.align == "left" then
                return icon .. ft
            else
                return ft .. icon
            end
        end
    end
    return ret
end

return M
