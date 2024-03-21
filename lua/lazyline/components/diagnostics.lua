local M = {}

local severityNames = {
    "error",
    "warn",
    "info",
    "hint",
}
local defaultSymbols = {
    error = '󰅚 ', -- x000f015a
    warn = '󰀪 ', -- x000f002a
    info = '󰋽 ', -- x000f02fd
    hint = '󰌶 ', -- x000f0336
}
local defaultColors = function()
    return {
        error = {
            fg = require('lazyline').extractColors(
                { 'fg', 'sp' },
                { 'DiagnosticError', 'LspDiagnosticsDefaultError', 'DiffDelete' },
                '#e32636'
            ).fg,
        },
        warn = {
            fg = require('lazyline').extractColors(
                { 'fg', 'sp' },
                { 'DiagnosticWarn', 'LspDiagnosticsDefaultWarning', 'DiffText' },
                '#ffa500'
            ).fg,
        },
        info = {
            fg = require('lazyline').extractColors(
                { 'fg', 'sp' },
                { 'DiagnosticInfo', 'LspDiagnosticsDefaultInformation', 'Normal' },
                '#ffffff'
            ).fg,
        },
        hint = {
            fg = require('lazyline').extractColors(
                { 'fg', 'sp' },
                { 'DiagnosticHint', 'LspDiagnosticsDefaultHint', 'DiffChange' },
                '#273faf'
            ).fg,
        },
    }
end

---@param v table
function M.new(v)
    if type(defaultColors) == "function" then
        ---@diagnostic disable-next-line: cast-local-type
        defaultColors = defaultColors()
    end
    local actual = require('lazyline.components').mergeCapabilities(v, {
        symbols = defaultSymbols,
        diagnostics_color = defaultColors,
        events = { "DiagnosticChanged", "BufEnter" },
        fmt = require('lazyline.components').pad,
    })
    local ret = actual
    ret[1] = function()
        local diagnostics = vim.diagnostic.get(0)
        local counts = { 0, 0, 0, 0 }
        for _, d in ipairs(diagnostics) do
            counts[d.severity] = counts[d.severity] + 1
        end
        local r = ""
        for s, count in ipairs(counts) do
            local severityName = severityNames[s]
            if count ~= 0 then
                local symbol = actual.symbols[severityName] or defaultSymbols[severityName]
                local color = actual.diagnostics_color[severityName] or defaultColors[severityName]
                color = vim.deepcopy(color)
                local hl = require('lazyline').getHl(color)
                r = r .. " %#" .. hl .. "#"
                r = r .. symbol .. count .. "%*"
            end
        end
        return r
    end
    return ret
end

return M
