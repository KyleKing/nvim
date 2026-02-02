-- Test editing support plugins (mini.comment, mini.surround, mini.hipatterns, etc.)
local MiniTest = require("mini.test")
local helpers = require("tests.helpers")

local T = MiniTest.new_set({
    hooks = {
        pre_case = function()
            -- Clean up before each test
        end,
    },
})

T["editing support"] = MiniTest.new_set()

T["mini.comment"] = MiniTest.new_set()

T["mini.comment"]["mini.comment is configured"] = function()
    -- Wait for later() to execute
    vim.wait(1000)
    MiniTest.expect.equality(helpers.is_plugin_loaded("mini.comment"), true, "mini.comment should be loaded")
end

T["mini.comment"]["comment mappings are set"] = function()
    vim.wait(1000)

    -- Check that gcc mapping exists for line comment
    local keymap = vim.fn.maparg("gcc", "n", false, true)
    MiniTest.expect.equality(keymap ~= nil and keymap.lhs ~= nil, true, "gcc mapping should exist")
end

T["mini.comment"]["can comment Lua code"] = function()
    vim.wait(1000)

    local bufnr = helpers.create_test_buffer({ "local x = 1" }, "lua")
    vim.api.nvim_set_current_buf(bufnr)

    -- Set cursor to first line
    vim.api.nvim_win_set_cursor(0, { 1, 0 })

    -- Trigger comment
    vim.cmd("normal gcc")

    -- Get the line
    local line = vim.api.nvim_buf_get_lines(bufnr, 0, 1, false)[1]

    -- Should be commented (Lua uses --)
    local is_commented = line:match("^%s*%-%-")
    MiniTest.expect.equality(is_commented ~= nil, true, "Line should be commented")

    helpers.delete_buffer(bufnr)
end

T["mini.comment"]["can comment Python code"] = function()
    vim.wait(1000)

    local bufnr = helpers.create_test_buffer({ "x = 1" }, "python")
    vim.api.nvim_set_current_buf(bufnr)

    vim.api.nvim_win_set_cursor(0, { 1, 0 })
    vim.cmd("normal gcc")

    local line = vim.api.nvim_buf_get_lines(bufnr, 0, 1, false)[1]

    -- Should be commented (Python uses #)
    local is_commented = line:match("^%s*#")
    MiniTest.expect.equality(is_commented ~= nil, true, "Line should be commented")

    helpers.delete_buffer(bufnr)
end

T["mini.comment"]["can comment TypeScript code"] = function()
    vim.wait(1000)

    local bufnr = helpers.create_test_buffer({ "const x = 1;" }, "typescript")
    vim.api.nvim_set_current_buf(bufnr)

    vim.api.nvim_win_set_cursor(0, { 1, 0 })
    vim.cmd("normal gcc")

    local line = vim.api.nvim_buf_get_lines(bufnr, 0, 1, false)[1]

    -- Should be commented (TypeScript uses //)
    local is_commented = line:match("^%s*//")
    MiniTest.expect.equality(is_commented ~= nil, true, "Line should be commented")

    helpers.delete_buffer(bufnr)
end

T["mini.surround"] = MiniTest.new_set()

T["mini.surround"]["mini.surround is configured"] = function()
    vim.wait(1000)
    MiniTest.expect.equality(helpers.is_plugin_loaded("mini.surround"), true, "mini.surround should be loaded")
end

T["mini.surround"]["surround mappings are set"] = function()
    vim.wait(1000)

    -- Check that surround mappings exist
    local check_keymap = function(lhs, mode)
        local keymap = vim.fn.maparg(lhs, mode, false, true)
        MiniTest.expect.equality(keymap ~= nil and keymap.lhs ~= nil, true, lhs .. " mapping should exist in " .. mode)
    end

    check_keymap("sa", "n") -- Add
    check_keymap("sd", "n") -- Delete
    check_keymap("sr", "n") -- Replace
    check_keymap("sf", "n") -- Find
    check_keymap("sF", "n") -- Find left
    check_keymap("sh", "n") -- Highlight
    check_keymap("sn", "n") -- Update n_lines
end

T["mini.surround"]["s key is disabled"] = function()
    vim.wait(1000)

    -- Check that 's' is disabled (mapped to <Nop>)
    local keymap = vim.fn.maparg("s", "n", false, true)
    MiniTest.expect.equality(keymap ~= nil, true, "s should be mapped")
    -- Should be mapped to nop or empty
    local is_nop = keymap.rhs == "" or keymap.rhs == "<Nop>"
    MiniTest.expect.equality(is_nop, true, "s should be disabled")
end

T["mini.surround"]["can add surround with quotes"] = function()
    vim.wait(1000)

    local bufnr = helpers.create_test_buffer({ "word" }, "text")
    vim.api.nvim_set_current_buf(bufnr)

    -- Move cursor to 'w'
    vim.api.nvim_win_set_cursor(0, { 1, 0 })

    -- Add surround: sa + iw (inner word) + " (double quote)
    vim.cmd('normal saiw"')

    local line = vim.api.nvim_buf_get_lines(bufnr, 0, 1, false)[1]
    MiniTest.expect.equality(line, '"word"', "Word should be surrounded by quotes")

    helpers.delete_buffer(bufnr)
end

T["mini.surround"]["can delete surround"] = function()
    vim.wait(1000)

    local bufnr = helpers.create_test_buffer({ '"word"' }, "text")
    vim.api.nvim_set_current_buf(bufnr)

    -- Move cursor inside quotes
    vim.api.nvim_win_set_cursor(0, { 1, 2 })

    -- Delete surround: sd + " (double quote)
    vim.cmd('normal sd"')

    local line = vim.api.nvim_buf_get_lines(bufnr, 0, 1, false)[1]
    MiniTest.expect.equality(line, "word", "Quotes should be deleted")

    helpers.delete_buffer(bufnr)
end

T["mini.surround"]["can replace surround"] = function()
    vim.wait(1000)

    local bufnr = helpers.create_test_buffer({ '"word"' }, "text")
    vim.api.nvim_set_current_buf(bufnr)

    -- Move cursor inside quotes
    vim.api.nvim_win_set_cursor(0, { 1, 2 })

    -- Replace surround: sr + " (from) + ' (to)
    vim.cmd([[normal sr"']])

    local line = vim.api.nvim_buf_get_lines(bufnr, 0, 1, false)[1]
    MiniTest.expect.equality(line, "'word'", "Quotes should be replaced with single quotes")

    helpers.delete_buffer(bufnr)
end

T["mini.operators"] = MiniTest.new_set()

T["mini.operators"]["mini.operators is loaded"] = function()
    vim.wait(1000)
    MiniTest.expect.equality(helpers.is_plugin_loaded("mini.operators"), true, "mini.operators should be loaded")
end

T["mini.operators"]["sort keymap exists"] = function()
    vim.wait(1000)
    local keymap = vim.fn.maparg("gs", "n", false, true)
    MiniTest.expect.equality(keymap ~= nil and keymap.lhs ~= nil, true, "gs mapping should exist")
end

T["mini.operators"]["gx still maps to gx.nvim"] = function()
    vim.wait(1000)
    local keymap = vim.fn.maparg("gx", "n", false, true)
    MiniTest.expect.equality(keymap ~= nil and keymap.lhs ~= nil, true, "gx mapping should exist")
    local desc = keymap.desc or ""
    MiniTest.expect.equality(desc:lower():find("browse") ~= nil, true, "gx should map to Browse, got: " .. desc)
end

T["mini.operators"]["sorts comma-separated values"] = function()
    vim.wait(1000)

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
    vim.wait(1000)

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
    vim.wait(1000)

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

T["other editing plugins"] = MiniTest.new_set()

T["other editing plugins"]["highlight-undo is configured"] = function()
    vim.wait(1000)
    MiniTest.expect.equality(helpers.is_plugin_loaded("highlight-undo"), true, "highlight-undo should be loaded")
end

T["other editing plugins"]["mini.move is configured"] = function()
    vim.wait(1000)
    MiniTest.expect.equality(helpers.is_plugin_loaded("mini.move"), true, "mini.move should be loaded")
end

T["other editing plugins"]["mini.trailspace is configured"] = function()
    vim.wait(1000)
    MiniTest.expect.equality(helpers.is_plugin_loaded("mini.trailspace"), true, "mini.trailspace should be loaded")
end

T["other editing plugins"]["mini.hipatterns is configured"] = function()
    vim.wait(1000)
    MiniTest.expect.equality(helpers.is_plugin_loaded("mini.hipatterns"), true, "mini.hipatterns should be loaded")
end

T["other editing plugins"]["mini.ai is configured"] = function()
    vim.wait(1000)
    MiniTest.expect.equality(helpers.is_plugin_loaded("mini.ai"), true, "mini.ai should be loaded")
end

-- For manual running
if ... == nil then MiniTest.run() end

return T
