---@class ConfigHarpoonTablineValues
---@field exclude? string[]
---@field include? string[]
---@field selected? string

---@param harpoon Harpoon
---@param opts ConfigHarpoonTablineValues
local function genTabline(harpoon, opts)
    local currentFile = vim.fn.expand("%:p")
    currentFile = vim.fn.fnamemodify(currentFile, ":.")
    opts.selected = opts.selected or currentFile
    local tabline = ""
    local tabLen = 0
    local display = harpoon:list():display()
    display = vim.tbl_filter(function(x) return x ~= "" end, display)
    display = vim.tbl_filter(function(x) return not vim.tbl_contains(opts.exclude or {}, x) end, display)
    for _, dir in ipairs(opts.include or {}) do
        table.insert(display, dir)
    end
    local extras = {}
    for _, dir in ipairs(display) do
        extras[dir] = (extras[dir] or 0) + 1
    end
    for i = #display, 1, -1 do
        local dir = display[i]
        if extras[dir] > 1 then
            table.remove(display, i)
            extras[dir] = extras[dir] - 1
        end
    end
    local separator = '/'
    if jit.os == "Windows" then
        separator = '\\'
    end
    local justNames = vim.tbl_map(function(x) return vim.fn.split(x, separator)[#vim.fn.split(x, separator)] end, display)
    local past = {}
    for i, dir in ipairs(justNames) do
        if past[dir] == nil then
            past[dir] = { i }
        else
            table.insert(past[dir], i)
            for _, j in ipairs(past[dir]) do
                justNames[j] = display[j]
            end
        end
    end
    local selIndex = 0
    for i, dir in ipairs(justNames) do
        if display[i] == opts.selected then
            selIndex = i
            break
        end
    end
    -- print(harpoon:list():length())
    local tablineNames = vim.fn.split(vim.g.TablineNames or '', ',')
    tablineNames = vim.tbl_map(function(n)
        if n == '' then return nil end
        return n
    end, tablineNames)
    for i, dir in ipairs(justNames) do
        local name = dir
        local active = i == selIndex
        if active then
            tabline = tabline .. "%#TablineSel#"
        else
            tabline = tabline .. "%#Tabline#"
        end
        local start = #tabline
        tabline = tabline .. "   "
        tabline = tabline .. i
        tabline = tabline .. " " .. name .. " "
        tabline = tabline .. "   "
        tabLen = tabLen + #tabline - start
        if active then
            tabline = tabline .. "%#TablineSel#"
        else
            tabline = tabline .. "%#Tabline#"
        end
    end
    tabline = tabline .. "%#Tabline#"

    local pageList = ""
    local pageLen = 0
    for i, v in ipairs(vim.api.nvim_list_tabpages()) do
        if v == vim.api.nvim_get_current_tabpage() then
            pageList = pageList .. "%#TablineSel#"
        else
            pageList = pageList .. "%#Tabline#"
        end
        local start = #pageList
        pageList = pageList .. "  "
        if tablineNames[i] ~= nil then
            pageList = pageList .. tablineNames[i]
        else
            pageList = pageList .. v
        end
        pageList = pageList .. '  '
        pageLen = pageLen + #pageList - start
    end
    if #vim.api.nvim_list_tabpages() ~= 1 then
        local width = tonumber(vim.api.nvim_exec2("echo &columns", { output = true }).output) or 0
        local extra = width - pageLen - tabLen
        tabline = tabline .. string.rep(' ', extra)
        tabline = tabline .. pageList
    end
    -- print(vim.inspect(tabline))
    vim.o.tabline = tabline
end
local function regenTabline(tablineNames)
    local harpoon = require('harpoon')
    vim.g.TablineNames = ""
    for _, v in ipairs(tablineNames) do
        vim.g.TablineNames = vim.g.TablineNames .. v .. ','
    end
    vim.defer_fn(function()
        genTabline(harpoon, {})
    end, 50)
end

local function getIndexFromTablineNumber(num)
    for i, v in ipairs(vim.api.nvim_list_tabpages()) do
        if v == num then
            return i
        end
    end
    return 0
end

local ret = function()
    local harpoon = require("harpoon")
    vim.api.nvim_create_autocmd("TabEnter", {
        callback = function()
            genTabline(harpoon, {})
        end
    })
    vim.api.nvim_create_autocmd("BufEnter", {
        callback = function()
            vim.defer_fn(function()
                genTabline(harpoon, {})
            end, 50)
        end
    })
    genTabline(harpoon, {})
    vim.api.nvim_create_user_command("TablineShiftByAfter", function(opts)
        local shift = tonumber(opts.fargs[1])
        while shift == nil do
            shift = tonumber(vim.fn.input("Shift number: "))
        end
        local index = tonumber(opts.fargs[2])
        while index == nil or index < 1 do
            index = tonumber(vim.fn.input("Tabline index (not number): "))
        end
        local tablineNames = vim.fn.split(vim.g.TablineNames or '', ',')
        local startLen = #tablineNames
        if shift < 0 then
            while startLen + shift < #tablineNames do
                table.remove(tablineNames, index)
            end
        end
        if shift > 0 then
            while startLen + shift > #tablineNames do
                table.insert(tablineNames, index, '')
            end
        end
        while #tablineNames > #vim.api.nvim_list_tabpages() do
            table.remove(tablineNames, #tablineNames)
        end
        regenTabline(tablineNames)
    end, {
        nargs = '*',
    })
    vim.api.nvim_create_user_command("TablineRename", function(opts)
        local num = tonumber(opts.fargs[1])
        while num == nil do
            num = tonumber(vim.fn.input("Input a tabline index (not the number): "))
        end
        local name = opts.fargs[2]
        if name == nil then
            name = vim.fn.input("Give it a name: ")
        end
        local tablineNames = vim.fn.split(vim.g.TablineNames or '', ',')
        while #tablineNames < num do
            table.insert(tablineNames, '')
        end
        tablineNames[num] = name
        regenTabline(tablineNames)
    end, {
        nargs = '*',
    })
    vim.api.nvim_create_autocmd("TabNew", {
        callback = function(opts)
            -- local newPage = vim.api.nvim_tabpage_get_number(0)
            -- print(getIndexFromTablineNumber(newPage) - 1)
            -- vim.cmd("TablineShiftByAfter 1 " .. (getIndexFromTablineNumber(newPage) - 1))
        end
    })
    return {
        ADD = function(cx)
            genTabline(harpoon, { include = { cx.item.value } })
        end,
        SELECT = function(cx)
            genTabline(harpoon, { selected = cx.item.value })
        end,
        REMOVE = function(cx)
            genTabline(harpoon, { exclude = { cx.item.value } })
        end,
        REORDER = function()
            genTabline(harpoon, {})
        end,
    }
end
local M = {}
M.setup = function()
    ---@diagnostic disable-next-line: cast-local-type
    ret = ret()

    return ret
end
M.get = function()
    if type(ret) == "function" then
        ---@diagnostic disable-next-line: cast-local-type
        ret = ret()
    end
    return ret
end
return M
