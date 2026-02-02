-- Test mini.ai integration
local MiniTest = require("mini.test")
local helpers = require("tests.helpers")

local T = MiniTest.new_set({
    hooks = {
        pre_case = function()
            -- Clean up before each test
        end,
    },
})

T["mini.ai"] = MiniTest.new_set()

T["mini.ai"]["mini.ai is loaded"] = function()
    vim.wait(1000)
    MiniTest.expect.equality(helpers.is_plugin_loaded("mini.ai"), true, "mini.ai should be loaded")
end

T["mini.ai"]["mini.ai is configured"] = function()
    vim.wait(1000)
    local MiniAi = require("mini.ai")
    MiniTest.expect.no_error(function() return MiniAi.config end, "mini.ai config should be accessible")
end

T["mini.ai"]["can select around next argument (vaN)"] = function()
    vim.wait(1000)

    -- Create test buffer with function call
    local bufnr = helpers.create_test_buffer({ "func(arg1, arg2, arg3)" }, "lua")
    vim.api.nvim_set_current_buf(bufnr)

    -- Position cursor before first argument
    vim.api.nvim_win_set_cursor(0, { 1, 5 })

    -- Select around next argument: vaN
    vim.cmd("normal vaN")

    -- Get visual selection
    local start_pos = vim.fn.getpos("'<")
    local end_pos = vim.fn.getpos("'>")

    -- Should select "arg1, " (around next argument includes trailing delimiter)
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
    vim.wait(1000)

    local bufnr = helpers.create_test_buffer({ "local x = { 1, 2, 3 }" }, "lua")
    vim.api.nvim_set_current_buf(bufnr)

    -- Position cursor inside brackets
    vim.api.nvim_win_set_cursor(0, { 1, 12 })

    -- Select inside brackets: vib
    vim.cmd("normal vib")

    -- Get visual selection
    local start_pos = vim.fn.getpos("'<")
    local end_pos = vim.fn.getpos("'>")

    local line = vim.api.nvim_buf_get_lines(bufnr, 0, 1, false)[1]
    local selected = line:sub(start_pos[3], end_pos[3])

    -- Should select content inside brackets
    MiniTest.expect.equality(
        selected:match("1.*2.*3") ~= nil,
        true,
        "Should select inside brackets (got: " .. selected .. ")"
    )

    helpers.delete_buffer(bufnr)
end

T["mini.ai"]["can select around quotes (vaq)"] = function()
    vim.wait(1000)

    local bufnr = helpers.create_test_buffer({ 'local s = "hello world"' }, "lua")
    vim.api.nvim_set_current_buf(bufnr)

    -- Position cursor inside quotes
    vim.api.nvim_win_set_cursor(0, { 1, 12 })

    -- Select around quotes: vaq
    vim.cmd("normal vaq")

    local start_pos = vim.fn.getpos("'<")
    local end_pos = vim.fn.getpos("'>")

    local line = vim.api.nvim_buf_get_lines(bufnr, 0, 1, false)[1]
    local selected = line:sub(start_pos[3], end_pos[3])

    -- Should include quotes
    MiniTest.expect.equality(
        selected:match('^".*"$') ~= nil,
        true,
        "Should select around quotes including quotes (got: " .. selected .. ")"
    )

    helpers.delete_buffer(bufnr)
end

T["mini.ai"]["can delete around function (daf)"] = function()
    vim.wait(1000)

    local bufnr = helpers.create_test_buffer({
        "local result = func(arg)",
        "return result",
    }, "lua")
    vim.api.nvim_set_current_buf(bufnr)

    -- Position cursor on function call
    vim.api.nvim_win_set_cursor(0, { 1, 15 })

    -- Delete around function: daf
    vim.cmd("normal daf")

    local line = vim.api.nvim_buf_get_lines(bufnr, 0, 1, false)[1]

    -- Function call should be deleted
    MiniTest.expect.equality(line:match("func%(") == nil, true, "Function call should be deleted (got: " .. line .. ")")

    helpers.delete_buffer(bufnr)
end

T["mini.ai"]["text objects work with operators"] = function()
    vim.wait(1000)

    -- Test that mini.ai text objects work with operators like d, c, y
    local bufnr = helpers.create_test_buffer({ "(text)" }, "text")
    vim.api.nvim_set_current_buf(bufnr)

    vim.api.nvim_win_set_cursor(0, { 1, 2 })

    -- Delete inside brackets: dib
    vim.cmd("normal dib")

    local line = vim.api.nvim_buf_get_lines(bufnr, 0, 1, false)[1]

    -- Should have empty parens
    MiniTest.expect.equality(line, "()", "Should delete text inside brackets")

    helpers.delete_buffer(bufnr)
end

T["mini.ai"]["n_lines config is respected"] = function()
    vim.wait(1000)

    local MiniAi = require("mini.ai")

    -- Check that n_lines is set to 500 as configured
    MiniTest.expect.equality(MiniAi.config.n_lines, 500, "n_lines should be set to 500")
end

T["mini.ai"]["search_method config is set"] = function()
    vim.wait(1000)

    local MiniAi = require("mini.ai")

    -- Check that search_method is set correctly
    MiniTest.expect.equality(MiniAi.config.search_method, "cover_or_next", "search_method should be 'cover_or_next'")
end

-- For manual running
if ... == nil then MiniTest.run() end

return T
