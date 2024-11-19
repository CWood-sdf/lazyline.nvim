local M = {}
local status = {}
local timeSpent = 0
local jobs = {}

---@class LazyLine.CacheElement
---@field public line string
---@field public time number
---@field public dirty boolean

---@type LazyLine.CacheElement[]
local cache = {

}
local currentHl = 0
local currentI = 1
---@param str string A string that's in a format like 1h, 30m, 1h30m, 1h 30m, 1h 30m 30s
---@return integer
function M.lengthStrToDelta(str)
    local seconds = 0
    local tempStr = ""
    local mult = false
    if str:sub(1, 1) == "-" then
        mult = true
        str = str:sub(2)
    end
    for i = 1, #str do
        local char = str:sub(i, i)
        if char:match("%d") then
            tempStr = tempStr .. char
        elseif tempStr ~= "" then
            local unit = str:sub(i, i)
            if unit == "h" then
                seconds = seconds + (tonumber(tempStr) * 3600)
            elseif unit == "m" then
                seconds = seconds + (tonumber(tempStr) * 60)
            elseif unit == "s" then
                seconds = seconds + tonumber(tempStr)
            elseif unit == "d" then
                seconds = seconds + (tonumber(tempStr) * 86400)
            else
                error("Invalid unit: " .. unit)
            end
            tempStr = ""
        end
    end
    if mult then
        seconds = seconds * -1
    end

    return seconds
end

function M.getHl(opts)
    local statusHl = vim.api.nvim_get_hl(0, { name = "Statusline" })
    if type(opts) == "function" then
        opts = opts()
    end
    opts.gui = nil
    opts.bg = opts.bg or statusHl.bg
    opts.foreground = opts.fg or opts.foreground or statusHl.fg
    opts.fg = nil
    local group = "LazyLine_" .. currentI .. "_" .. currentHl
    currentHl = currentHl + 1
    vim.api.nvim_set_hl(0, group, opts)
    return group
end

function M.renderLine()
    local str = ""
    for _, job in ipairs(jobs) do
        local i = job.index
        if job.events == "*" or vim.tbl_contains(job.events or {}, "*") then
            job.lastRun = vim.loop.hrtime()
            job[1](function()
                cache[i] = cache[i] or {}
                cache[i].dirty = true
                M.renderLine()
            end)
        end
    end
    local startTime = vim.loop.hrtime()
    for i, v in ipairs(status) do
        currentI = i
        currentHl = 0
        if (v.events == "*" or vim.tbl_contains(v.events or {}, "*")) and cache[i] ~= nil then
            cache[i].dirty = true
        end
        if v.cond ~= nil and type(v.cond) == "function" and not v.cond() then
            goto continue
        end
        if cache[i] ~= nil and not cache[i].dirty then
            -- if cache[i].hasColor then
            --     str = str .. "%#" .. "LazyLine_" .. i .. "#"
            -- end
            str = str .. cache[i].line
            -- if cache[i].hasColor then
            --     str = str .. "%*"
            -- end
            goto continue
        end
        local s = ""
        if v.color ~= nil then
            local color = vim.fn.deepcopy(v.color) or {}
            local group = M.getHl(color)
            s = s .. "%#" .. group .. "#"
        end
        local s2 = v[1]
        if type(s2) == "function" then
            s2 = s2()
        end
        if type(s2) ~= "string" then
            goto continue
        end
        if s2 == "" then
            goto skip
        end
        if v.fmt ~= nil then
            s2 = v.fmt(s2)
        end
        s = s .. s2

        ::skip::
        if v.color ~= nil then
            s = s .. "%*"
        end
        str = str .. s
        cache[i] = {
            line = s,
            time = vim.loop.hrtime(),
            dirty = false,
        }
        -- str = str .. " "
        ::continue::
    end
    vim.go.statusline = str
    timeSpent = timeSpent + vim.loop.hrtime() - startTime
end

--- "#98be65"
---
local timer = nil

---@generic T
---@param a T
---@param _ any
---@return T
local function first(a, _)
    return a
end

function M.extractColors(fields, hls, default)
    local ret = {}
    for _, v in ipairs(hls) do
        if vim.fn.hlexists(v) then
            local col = vim.api.nvim_get_hl(0, { name = v })
            -- print(vim.inspect(col))
            for _, scope in ipairs(fields) do
                if col[scope] == nil or ret[scope] ~= nil then
                    goto continue
                end
                ret[scope] = string.format("#%06x", col[scope])
                ::continue::
            end
        end
    end
    for _, scope in ipairs(fields) do
        if ret[scope] == nil then
            ret[scope] = default
        end
    end
    return ret
end

---@param e string
---@return boolean
function M.isSpecialEvent(e)
    if e == "*" or e:sub(1, 1) == "(" then
        return true
    end
    return false
end

function M.setupEvents(events, index)
    if type(events) == "string" then
        events = { events }
    end
    -- events = vim.tbl_filter(function(str)
    --     return not M.isSpecialEvent(str)
    -- end, events)
    if #events == 0 then
        return
    end
    for _, e in ipairs(events) do
        if M.isSpecialEvent(e) then
            -- print(e)
            if e:sub(1, 1) == "(" then
                local s = e:sub(2, #e - 1)
                local delta = M.lengthStrToDelta(s) * 1000
                vim.fn.timer_start(delta, function()
                    cache[index] = cache[index] or {}
                    cache[index].dirty = true
                    M.renderLine()
                end, { ["repeat"] = -1 })
            end
        else
            local stuff = vim.fn.split(e, " ")
            vim.api.nvim_create_autocmd(stuff[1], {
                pattern = stuff[2],
                callback = function()
                    cache[index] = cache[index] or {}
                    cache[index].dirty = true
                    M.renderLine()
                end,
            })
        end
    end
end

function M.setupJobs(arr, index)
    for _, j in ipairs(arr) do
        table.insert(jobs, vim.deepcopy(j))
        if type(j.events) == "string" then
            j.events = { j.events }
        end
        if type(j.events) == "nil" then
            error("A job must have events")
        end
        local events = j.events
        jobs[#jobs].lastRun = 0
        jobs[#jobs].index = index
        if #events == 0 then
            goto continue
        end
        ---@cast events string[]
        for _, e in ipairs(events) do
            -- vim.notify(e)
            if M.isSpecialEvent(e) then
                -- vim.notify(e)
                if e:sub(1, 1) == "(" then
                    local s = e:sub(2, #e - 1)
                    local delta = M.lengthStrToDelta(s) * 1000
                    vim.fn.timer_start(delta, function()
                        j[1](function()
                            cache[index] = cache[index] or {}
                            cache[index].dirty = true
                            M.renderLine()
                        end)
                    end, { ["repeat"] = -1 })
                end
            else
                local stuff = vim.fn.split(e, " ")
                vim.api.nvim_create_autocmd(stuff[1], {
                    pattern = stuff[2],
                    callback = function()
                        j[1](function()
                            cache[index] = cache[index] or {}
                            cache[index].dirty = true
                            M.renderLine()
                        end)
                    end,
                })
            end
        end
        ::continue::
    end
end

function M.setup(opts)
    -- local ns = vim.api.nvim_create_namespace("Lazyline")
    local statusline = {}
    for _, v in ipairs(opts.sections.lualine_c) do
        table.insert(statusline, v)
    end
    table.insert(statusline, { "%=" })
    for _, v in ipairs(opts.sections.lualine_x) do
        table.insert(statusline, v)
    end
    status = statusline

    vim.defer_fn(function()
        for i, v in ipairs(status) do
            if type(v[1]) == "string" and first(pcall(require, "lazyline.components." .. v[1])) then
                -- vim.notify(vim.inspect(v))
                status[i] = require('lazyline.components.' .. v[1]).new(v)
            end
            if type(v.events) == "string" then
                v.events = { v.events }
            end
            v.fmt = v.fmt or require('lazyline.components').pad
        end
        for i, v in ipairs(status) do
            if v.events ~= nil then
                M.setupEvents(v.events, i)
            end
            if v.jobs ~= nil then
                M.setupJobs(v.jobs, i)
            end
        end
        vim.api.nvim_set_option("laststatus", 3)
        -- vim.go.statusline = "%#Yeet1#yeet %=%*yeet%=yeet%*%= yeet%= yeet%= yeet"
        M.renderLine()
        vim.fn.timer_start(10000, M.renderLine, { ["repeat"] = -1 })
        -- vim.g.statusline = "%1*yeet %=%*yeet%= yeet%= yeet%= yeet%= yeet"
    end, 100)
end

function M.getTimeSpent()
    return timeSpent
end

return M
