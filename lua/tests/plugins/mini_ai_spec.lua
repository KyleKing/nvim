-- Test mini.ai integration
local MiniTest = require("mini.test")
local helpers = require("tests.helpers")

local T = MiniTest.new_set({
    hooks = {
        pre_case = function() vim.wait(1000) end,
    },
})

T["mini.ai"] = MiniTest.new_set()

T["mini.ai"]["can select around next argument (vaN)"] = function()
    local bufnr = helpers.create_test_buffer({ "func(arg1, arg2, arg3)" }, "lua")
    vim.api.nvim_set_current_buf(bufnr)

    vim.api.nvim_win_set_cursor(0, { 1, 5 })
    vim.cmd("normal vaN")

    local start_pos = vim.fn.getpos("'<")
    local end_pos = vim.fn.getpos("'>")

    local line = vim.api.nvim_buf_get_lines(bufnr, 0, 1, false)[1]
    local selected = line:sub(start_pos[3], end_pos[3])

    MiniTest.expect.equality(
        selected:match("arg1") ~= nil,
        true,
        "Should select around next argument (got: " .. selected .. ")"
    )

    helpers.delete_buffer(bufnr)
end

T["mini.ai"]["can select inside brackets (vib)"] = function()
    local bufnr = helpers.create_test_buffer({ "local x = { 1, 2, 3 }" }, "lua")
    vim.api.nvim_set_current_buf(bufnr)

    vim.api.nvim_win_set_cursor(0, { 1, 12 })
    vim.cmd("normal vib")

    local start_pos = vim.fn.getpos("'<")
    local end_pos = vim.fn.getpos("'>")

    local line = vim.api.nvim_buf_get_lines(bufnr, 0, 1, false)[1]
    local selected = line:sub(start_pos[3], end_pos[3])

    MiniTest.expect.equality(
        selected:match("1.*2.*3") ~= nil,
        true,
        "Should select inside brackets (got: " .. selected .. ")"
    )

    helpers.delete_buffer(bufnr)
end

T["mini.ai"]["can select around quotes (vaq)"] = function()
    local bufnr = helpers.create_test_buffer({ 'local s = "hello world"' }, "lua")
    vim.api.nvim_set_current_buf(bufnr)

    vim.api.nvim_win_set_cursor(0, { 1, 12 })
    vim.cmd("normal vaq")

    local start_pos = vim.fn.getpos("'<")
    local end_pos = vim.fn.getpos("'>")

    local line = vim.api.nvim_buf_get_lines(bufnr, 0, 1, false)[1]
    local selected = line:sub(start_pos[3], end_pos[3])

    MiniTest.expect.equality(
        selected:match('^".*"$') ~= nil,
        true,
        "Should select around quotes including quotes (got: " .. selected .. ")"
    )

    helpers.delete_buffer(bufnr)
end

T["mini.ai"]["can delete around function (daf)"] = function()
    local bufnr = helpers.create_test_buffer({
        "local result = func(arg)",
        "return result",
    }, "lua")
    vim.api.nvim_set_current_buf(bufnr)

    vim.api.nvim_win_set_cursor(0, { 1, 15 })
    vim.cmd("normal daf")

    local line = vim.api.nvim_buf_get_lines(bufnr, 0, 1, false)[1]
    MiniTest.expect.equality(line:match("func%(") == nil, true, "Function call should be deleted (got: " .. line .. ")")

    helpers.delete_buffer(bufnr)
end

T["mini.ai"]["text objects work with operators"] = function()
    local bufnr = helpers.create_test_buffer({ "(text)" }, "text")
    vim.api.nvim_set_current_buf(bufnr)

    vim.api.nvim_win_set_cursor(0, { 1, 2 })
    vim.cmd("normal dib")

    local line = vim.api.nvim_buf_get_lines(bufnr, 0, 1, false)[1]
    MiniTest.expect.equality(line, "()", "Should delete text inside brackets")

    helpers.delete_buffer(bufnr)
end

T["mini.ai"]["n_lines config is respected"] = function()
    local MiniAi = require("mini.ai")
    MiniTest.expect.equality(MiniAi.config.n_lines, 500, "n_lines should be set to 500")
end

T["mini.ai"]["search_method config is set"] = function()
    local MiniAi = require("mini.ai")
    MiniTest.expect.equality(MiniAi.config.search_method, "cover_or_next", "search_method should be 'cover_or_next'")
end

-- For manual running
if ... == nil then MiniTest.run() end

return T
