local MiniTest = require("mini.test")

local T = MiniTest.new_set({
    hooks = {
        pre_case = function()
            vim.cmd("tabonly")
            vim.cmd("%bwipeout!")
        end,
    },
})

local file_opener = require("kyleking.utils.file_opener")

T["parse_file_location"] = MiniTest.new_set()

T["parse_file_location"]["parses simple file path"] = function()
    local temp_file = vim.fn.tempname() .. ".lua"
    vim.fn.writefile({}, temp_file)

    local result = file_opener.parse_file_location(temp_file)
    MiniTest.expect.equality(result ~= nil, true, "Result should not be nil")
    MiniTest.expect.equality(result.path, temp_file)
    MiniTest.expect.equality(result.line, nil)
    MiniTest.expect.equality(result.col, nil)

    vim.fn.delete(temp_file)
end

T["parse_file_location"]["parses file path with line number"] = function()
    local temp_file = vim.fn.tempname() .. ".lua"
    vim.fn.writefile({}, temp_file)

    local result = file_opener.parse_file_location(temp_file .. ":42")
    MiniTest.expect.equality(result ~= nil, true, "Result should not be nil")
    MiniTest.expect.equality(result.path, temp_file)
    MiniTest.expect.equality(result.line, 42)
    MiniTest.expect.equality(result.col, nil)

    vim.fn.delete(temp_file)
end

T["parse_file_location"]["parses file path with line and column"] = function()
    local temp_file = vim.fn.tempname() .. ".lua"
    vim.fn.writefile({}, temp_file)

    local result = file_opener.parse_file_location(temp_file .. ":42:10")
    MiniTest.expect.equality(result ~= nil, true, "Result should not be nil")
    MiniTest.expect.equality(result.path, temp_file)
    MiniTest.expect.equality(result.line, 42)
    MiniTest.expect.equality(result.col, 10)

    vim.fn.delete(temp_file)
end

T["parse_file_location"]["returns nil for non-existent file"] = function()
    local result = file_opener.parse_file_location("/tmp/nonexistent_file_12345.lua")
    MiniTest.expect.equality(result, nil)
end

T["parse_file_location"]["expands relative paths"] = function()
    local temp_file = vim.fn.tempname() .. ".lua"
    vim.fn.writefile({}, temp_file)

    local cwd = vim.fn.fnamemodify(temp_file, ":h")
    local basename = vim.fn.fnamemodify(temp_file, ":t")

    local result = file_opener.parse_file_location(basename, cwd)
    MiniTest.expect.equality(result ~= nil, true, "Result should not be nil")
    MiniTest.expect.equality(result.path, temp_file)

    vim.fn.delete(temp_file)
end

T["open_in_new_tab"] = MiniTest.new_set()

T["open_in_new_tab"]["opens file in new tab"] = function()
    local temp_file = vim.fn.tempname() .. ".lua"
    vim.fn.writefile({ "line 1", "line 2", "line 3" }, temp_file)

    local initial_tab_count = vim.fn.tabpagenr("$")
    local location = { path = temp_file, line = nil, col = nil }

    file_opener.open_in_new_tab(location)

    MiniTest.expect.equality(vim.fn.tabpagenr("$"), initial_tab_count + 1)
    MiniTest.expect.equality(vim.fn.expand("%:p"), temp_file)

    vim.fn.delete(temp_file)
end

T["open_in_new_tab"]["sets cursor to specified line"] = function()
    local temp_file = vim.fn.tempname() .. ".lua"
    vim.fn.writefile({ "line 1", "line 2", "line 3" }, temp_file)

    local location = { path = temp_file, line = 2, col = nil }
    file_opener.open_in_new_tab(location)

    local cursor = vim.api.nvim_win_get_cursor(0)
    MiniTest.expect.equality(cursor[1], 2)

    vim.fn.delete(temp_file)
end

T["open_in_new_tab"]["sets cursor to specified line and column"] = function()
    local temp_file = vim.fn.tempname() .. ".lua"
    vim.fn.writefile({ "line 1", "line 2 with text", "line 3" }, temp_file)

    local location = { path = temp_file, line = 2, col = 5 }
    file_opener.open_in_new_tab(location)

    local cursor = vim.api.nvim_win_get_cursor(0)
    MiniTest.expect.equality(cursor[1], 2)
    MiniTest.expect.equality(cursor[2], 4)

    vim.fn.delete(temp_file)
end

if ... == nil then MiniTest.run() end

return T
