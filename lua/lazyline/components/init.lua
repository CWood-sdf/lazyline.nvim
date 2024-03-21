local M = {}

---@param str string
---@return string
function M.pad(str)
    return " " .. str .. " "
end

---@param left string|string[]
---@param right string|string[]
function M.mergeEvents(left, right)
    local ret = {}
    if type(left) == "string" then
        table.insert(ret, left)
    else
        for _, v in ipairs(left) do
            table.insert(ret, v)
        end
    end
    if type(right) == "string" then
        if not vim.tbl_contains(ret, right) then
            table.insert(ret, right)
        end
    else
        for _, v in ipairs(right) do
            if not vim.tbl_contains(ret, v) then
                table.insert(ret, v)
            end
        end
    end


    return ret
end

function M.mergeCapabilities(config, default)
    local ret = {}
    if default.events ~= nil and config.events ~= nil then
        ret.events = M.mergeEvents(default.events, config.events)
    end
    if default.jobs ~= nil and config.jobs ~= nil then
        ret.jobs = {}
        for _, v in ipairs(default.jobs) do
            table.insert(ret.jobs, v)
        end
        for _, v in ipairs(config.jobs) do
            table.insert(ret.jobs, v)
        end
    end
    for k, v in pairs(config) do
        if ret[k] ~= nil then
            goto continue
        end
        if tonumber(k) ~= nil then
            goto continue
        end
        ret[k] = v
        ::continue::
    end
    for k, v in pairs(default) do
        if ret[k] ~= nil then
            goto continue
        end
        if tonumber(k) ~= nil then
            goto continue
        end
        ret[k] = v
        ::continue::
    end
    ret.fmt = ret.fmt or M.pad
    return ret
end

return M
