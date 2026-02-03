-- Test editing support plugins (mini.comment, mini.surround, mini.operators)
local MiniTest = require("mini.test")
local helpers = require("tests.helpers")

local T = MiniTest.new_set({
    hooks = {
        pre_case = function() helpers.wait_for_plugins() end,
    },
})

T["mini.comment"] = MiniTest.new_set()

T["mini.comment"]["can comment Lua code"] = function()
    local bufnr = helpers.create_test_buffer({ "local x = 1" }, "lua")
    vim.api.nvim_set_current_buf(bufnr)

    vim.api.nvim_win_set_cursor(0, { 1, 0 })
    vim.cmd("normal gcc")

    local line = vim.api.nvim_buf_get_lines(bufnr, 0, 1, false)[1]
    local is_commented = line:match("^%s*%-%-")
    MiniTest.expect.equality(is_commented ~= nil, true, "Line should be commented")

    helpers.delete_buffer(bufnr)
end

T["mini.comment"]["can comment Python code"] = function()
    local bufnr = helpers.create_test_buffer({ "x = 1" }, "python")
    vim.api.nvim_set_current_buf(bufnr)

    vim.api.nvim_win_set_cursor(0, { 1, 0 })
    vim.cmd("normal gcc")

    local line = vim.api.nvim_buf_get_lines(bufnr, 0, 1, false)[1]
    local is_commented = line:match("^%s*#")
    MiniTest.expect.equality(is_commented ~= nil, true, "Line should be commented")

    helpers.delete_buffer(bufnr)
end

T["mini.comment"]["can comment TypeScript code"] = function()
    local bufnr = helpers.create_test_buffer({ "const x = 1;" }, "typescript")
    vim.api.nvim_set_current_buf(bufnr)

    vim.api.nvim_win_set_cursor(0, { 1, 0 })
    vim.cmd("normal gcc")

    local line = vim.api.nvim_buf_get_lines(bufnr, 0, 1, false)[1]
    local is_commented = line:match("^%s*//")
    MiniTest.expect.equality(is_commented ~= nil, true, "Line should be commented")

    helpers.delete_buffer(bufnr)
end

T["mini.surround"] = MiniTest.new_set()

T["mini.surround"]["can add surround with quotes"] = function()
    local bufnr = helpers.create_test_buffer({ "word" }, "text")
    vim.api.nvim_set_current_buf(bufnr)

    vim.api.nvim_win_set_cursor(0, { 1, 0 })
    vim.cmd('normal saiw"')

    local line = vim.api.nvim_buf_get_lines(bufnr, 0, 1, false)[1]
    MiniTest.expect.equality(line, '"word"', "Word should be surrounded by quotes")

    helpers.delete_buffer(bufnr)
end

T["mini.surround"]["can delete surround"] = function()
    local bufnr = helpers.create_test_buffer({ '"word"' }, "text")
    vim.api.nvim_set_current_buf(bufnr)

    vim.api.nvim_win_set_cursor(0, { 1, 2 })
    vim.cmd('normal sd"')

    local line = vim.api.nvim_buf_get_lines(bufnr, 0, 1, false)[1]
    MiniTest.expect.equality(line, "word", "Quotes should be deleted")

    helpers.delete_buffer(bufnr)
end

T["mini.surround"]["can replace surround"] = function()
    local bufnr = helpers.create_test_buffer({ '"word"' }, "text")
    vim.api.nvim_set_current_buf(bufnr)

    vim.api.nvim_win_set_cursor(0, { 1, 2 })
    vim.cmd([[normal sr"']])

    local line = vim.api.nvim_buf_get_lines(bufnr, 0, 1, false)[1]
    MiniTest.expect.equality(line, "'word'", "Quotes should be replaced with single quotes")

    helpers.delete_buffer(bufnr)
end

T["mini.operators"] = MiniTest.new_set()

T["mini.operators"]["sorts comma-separated values"] = function()
    local bufnr = helpers.create_test_buffer({ "b,c,aa" }, "text")
    vim.api.nvim_set_current_buf(bufnr)

    vim.api.nvim_win_set_cursor(0, { 1, 0 })
    vim.cmd("normal V")
    vim.cmd("normal gs")

    local line = vim.api.nvim_buf_get_lines(bufnr, 0, 1, false)[1]
    MiniTest.expect.equality(line, "aa,b,c", "Comma-separated values should be sorted")

    helpers.delete_buffer(bufnr)
end

T["mini.operators"]["sorts semicolon-separated values"] = function()
    local bufnr = helpers.create_test_buffer({ "c; a; b" }, "text")
    vim.api.nvim_set_current_buf(bufnr)

    vim.api.nvim_win_set_cursor(0, { 1, 0 })
    vim.cmd("normal V")
    vim.cmd("normal gs")

    local line = vim.api.nvim_buf_get_lines(bufnr, 0, 1, false)[1]
    MiniTest.expect.equality(line, "a; b; c", "Semicolon-separated values should be sorted")

    helpers.delete_buffer(bufnr)
end

T["mini.operators"]["sorts lines in paragraph"] = function()
    local bufnr = helpers.create_test_buffer({ "cherry", "apple", "banana" }, "text")
    vim.api.nvim_set_current_buf(bufnr)

    vim.api.nvim_win_set_cursor(0, { 1, 0 })
    vim.cmd("normal gsip")

    local lines = vim.api.nvim_buf_get_lines(bufnr, 0, 3, false)
    MiniTest.expect.equality(lines[1], "apple", "First line should be apple")
    MiniTest.expect.equality(lines[2], "banana", "Second line should be banana")
    MiniTest.expect.equality(lines[3], "cherry", "Third line should be cherry")

    helpers.delete_buffer(bufnr)
end

-- For manual running
if ... == nil then MiniTest.run() end

return T
