local M = {}

function M.new(v)
    local diff = {
        added = 0,
        modified = 0,
        removed = 0,
    }
    local actual = require('lazyline.components').mergeCapabilities(v, {
        jobs = {
            {
                events = { "BufEnter", "BufWritePost" },
                function(render)
                    local job = string.format(
                        [[git -C %s --no-pager diff --no-color --no-ext-diff -U0 -- %s]],
                        vim.fn.expand('%:h'),
                        vim.fn.expand('%:t')
                    )
                    local stdout = ""
                    local added = 0
                    local modified = 0
                    local removed = 0
                    vim.fn.jobstart(job, {
                        on_stdout = function(_, data, _)
                            for _, str in ipairs(data) do
                                stdout = stdout .. str .. "\n"
                            end
                        end,
                        on_exit = function()
                            diff.added = 0
                            diff.modified = 0
                            diff.removed = 0
                            if stdout == "" then
                                render()
                                return
                            end
                            for _, line in ipairs(vim.fn.split(stdout, "\n")) do
                                if string.find(line, "^@@") then
                                    local tokens = vim.fn.matchlist(line, [[^@@ -\v(\d+),?(\d*) \+(\d+),?(\d*)]])
                                    local line_stats = {
                                        mod_count = tokens[3] == nil and 0 or tokens[3] == '' and 1 or
                                            tonumber(tokens[3]),
                                        new_count = tokens[5] == nil and 0 or tokens[5] == '' and 1 or
                                            tonumber(tokens[5]),
                                    }

                                    if line_stats.mod_count == 0 and line_stats.new_count > 0 then
                                        added = added + line_stats.new_count
                                    elseif line_stats.mod_count > 0 and line_stats.new_count == 0 then
                                        removed = removed + line_stats.mod_count
                                    else
                                        local min = math.min(line_stats.mod_count, line_stats.new_count)
                                        modified = modified + min
                                        added = added + line_stats.new_count - min
                                        removed = removed + line_stats.mod_count - min
                                    end
                                end
                            end
                            diff.added = added
                            diff.modified = modified
                            diff.removed = removed
                            render()
                        end,
                    })
                    render()
                end,
            },
        },
        fmt = require('lazyline.components').pad,
        symbols = {
            added = "+",
            modified = "~",
            removed = "-",
        },
        diff_color = {
            added = {
                fg = require('lazyline').extractColors(
                    { 'fg' },
                    { 'DiffAdd', 'DiffText' },
                    '#00ff00'
                ).fg,
            },
            modified = {
                fg = require('lazyline').extractColors(
                    { 'fg' },
                    { 'DiffChange', 'DiffText' },
                    '#ffff00'
                ).fg,
            },
            removed = {
                fg = require('lazyline').extractColors(
                    { 'fg' },
                    { 'DiffDelete', 'DiffText' },
                    '#ff0000'
                ).fg,
            },
        },
    })
    local ret = actual
    ret[1] = function()
        local added = diff.added
        local modified = diff.modified
        local removed = diff.removed
        local symbols = actual.symbols
        local diff_color = actual.diff_color
        local str = ""
        if added > 0 then
            local hl = require('lazyline').getHl(diff_color.added)
            str = str .. "%#" .. hl .. "#"
            str = str .. symbols.added .. added .. "%* "
        end
        if modified > 0 then
            local hl = require('lazyline').getHl(diff_color.modified)
            str = str .. "%#" .. hl .. "#"
            str = str .. symbols.modified .. modified .. "%* "
        end
        if removed > 0 then
            local hl = require('lazyline').getHl(diff_color.removed)
            str = str .. "%#" .. hl .. "#"
            str = str .. symbols.removed .. removed .. "%* "
        end
        str = str:sub(1, -2)
        return str
    end
    return ret
end

return M
