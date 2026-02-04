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

T["parse_file_location"]["handles relative paths with line and column"] = function()
    local temp_file = vim.fn.tempname() .. ".lua"
    vim.fn.writefile({}, temp_file)

    local cwd = vim.fn.fnamemodify(temp_file, ":h")
    local basename = vim.fn.fnamemodify(temp_file, ":t")

    local result = file_opener.parse_file_location(basename .. ":10:5", cwd)
    MiniTest.expect.equality(result ~= nil, true, "Result should not be nil")
    MiniTest.expect.equality(result.path, temp_file)
    MiniTest.expect.equality(result.line, 10)
    MiniTest.expect.equality(result.col, 5)

    vim.fn.delete(temp_file)
end

T["parse_file_location"]["handles nested relative paths"] = function()
    local temp_dir = vim.fn.tempname()
    vim.fn.mkdir(temp_dir, "p")
    local subdir = temp_dir .. "/subdir"
    vim.fn.mkdir(subdir, "p")
    local temp_file = subdir .. "/test.lua"
    vim.fn.writefile({}, temp_file)

    local result = file_opener.parse_file_location("subdir/test.lua", temp_dir)
    MiniTest.expect.equality(result ~= nil, true, "Result should not be nil")
    MiniTest.expect.equality(result.path, temp_file)

    vim.fn.delete(temp_dir, "rf")
end

T["parse_file_location"]["handles absolute path with tilde"] = function()
    local home = vim.fn.expand("~")
    local temp_file = vim.fn.tempname() .. ".lua"
    vim.fn.writefile({}, temp_file)

    if vim.startswith(temp_file, home) then
        local relative_to_home = "~" .. temp_file:sub(#home + 1)
        local expanded = vim.fn.expand(relative_to_home)

        local result = file_opener.parse_file_location(expanded)
        MiniTest.expect.equality(result ~= nil, true, "Result should not be nil")
        MiniTest.expect.equality(result.path, temp_file)
    end

    vim.fn.delete(temp_file)
end

T["parse_file_location"]["handles path with spaces"] = function()
    local temp_dir = vim.fn.tempname()
    vim.fn.mkdir(temp_dir, "p")
    local temp_file = temp_dir .. "/file with spaces.lua"
    vim.fn.writefile({}, temp_file)

    local result = file_opener.parse_file_location(temp_file)
    MiniTest.expect.equality(result ~= nil, true, "Result should not be nil")
    MiniTest.expect.equality(result.path, temp_file)

    vim.fn.delete(temp_dir, "rf")
end

T["parse_file_location"]["handles path with dots"] = function()
    local temp_dir = vim.fn.tempname()
    vim.fn.mkdir(temp_dir, "p")
    local subdir = temp_dir .. "/subdir"
    vim.fn.mkdir(subdir, "p")
    local temp_file = subdir .. "/test.lua"
    vim.fn.writefile({}, temp_file)

    local result = file_opener.parse_file_location("subdir/../subdir/test.lua", temp_dir)
    MiniTest.expect.equality(result ~= nil, true, "Result should not be nil")

    local normalized_result = vim.fn.resolve(vim.fn.fnamemodify(result.path, ":p"))
    local normalized_expected = vim.fn.resolve(vim.fn.fnamemodify(temp_file, ":p"))
    MiniTest.expect.equality(normalized_result, normalized_expected)

    vim.fn.delete(temp_dir, "rf")
end

T["open_from_terminal"] = MiniTest.new_set()

T["open_from_terminal"]["opens absolute path from terminal"] = function()
    local temp_file = vim.fn.tempname() .. ".lua"
    vim.fn.writefile({ "test content" }, temp_file)

    vim.cmd("tabnew")
    local _ = vim.fn.termopen({ vim.o.shell })
    vim.wait(500)

    local initial_tab_count = vim.fn.tabpagenr("$")

    file_opener.open_from_terminal(temp_file)

    vim.wait(500)

    MiniTest.expect.equality(vim.fn.tabpagenr("$"), initial_tab_count + 1, "Should open new tab")
    MiniTest.expect.equality(vim.fn.expand("%:p"), temp_file, "Should open correct file")

    vim.fn.delete(temp_file)
end

T["open_from_terminal"]["opens relative path from terminal cwd"] = function()
    local temp_dir = vim.fn.tempname()
    vim.fn.mkdir(temp_dir, "p")
    local temp_file = temp_dir .. "/test.lua"
    vim.fn.writefile({ "test content" }, temp_file)

    vim.cmd("tabnew")
    local term_bufnr = vim.fn.termopen({ vim.o.shell })
    vim.wait(500)

    vim.b[term_bufnr].terminal_job_cwd = temp_dir

    local initial_tab_count = vim.fn.tabpagenr("$")

    file_opener.open_from_terminal("test.lua")

    vim.wait(500)

    MiniTest.expect.equality(vim.fn.tabpagenr("$"), initial_tab_count + 1, "Should open new tab")
    MiniTest.expect.equality(vim.fn.expand("%:p"), temp_file, "Should open correct file")

    vim.fn.delete(temp_dir, "rf")
end

T["open_from_terminal"]["opens path with line number"] = function()
    local temp_file = vim.fn.tempname() .. ".lua"
    vim.fn.writefile({ "line 1", "line 2", "line 3" }, temp_file)

    vim.cmd("tabnew")
    local _ = vim.fn.termopen({ vim.o.shell })
    vim.wait(500)

    file_opener.open_from_terminal(temp_file .. ":2")

    vim.wait(500)

    local cursor = vim.api.nvim_win_get_cursor(0)
    MiniTest.expect.equality(cursor[1], 2, "Should jump to line 2")

    vim.fn.delete(temp_file)
end

T["open_from_terminal"]["opens path with line and column"] = function()
    local temp_file = vim.fn.tempname() .. ".lua"
    vim.fn.writefile({ "line 1", "line 2 with text", "line 3" }, temp_file)

    vim.cmd("tabnew")
    local _ = vim.fn.termopen({ vim.o.shell })
    vim.wait(500)

    file_opener.open_from_terminal(temp_file .. ":2:8")

    vim.wait(500)

    local cursor = vim.api.nvim_win_get_cursor(0)
    MiniTest.expect.equality(cursor[1], 2, "Should jump to line 2")
    MiniTest.expect.equality(cursor[2], 7, "Should jump to column 8")

    vim.fn.delete(temp_file)
end

T["open_from_terminal"]["shows warning for non-existent file"] = function()
    vim.cmd("tabnew")
    local _ = vim.fn.termopen({ vim.o.shell })
    vim.wait(500)

    local initial_tab_count = vim.fn.tabpagenr("$")

    local notified = false
    local original_notify = vim.notify
    vim.notify = function(msg, level)
        if level == vim.log.levels.WARN and msg:find("File not found") then notified = true end
    end

    file_opener.open_from_terminal("/tmp/nonexistent_file_12345.lua")

    vim.notify = original_notify

    vim.wait(500)

    MiniTest.expect.equality(notified, true, "Should notify about non-existent file")
    MiniTest.expect.equality(vim.fn.tabpagenr("$"), initial_tab_count, "Should not open new tab")
end

if ... == nil then MiniTest.run() end

return T
