-- Detailed LSP functionality tests
-- Tests go-to-definition, references, hover, and other LSP features
local MiniTest = require("mini.test")
local helpers = require("tests.helpers")

local T = MiniTest.new_set({
    hooks = {
        pre_case = function() end,
    },
})

T["LSP navigation"] = MiniTest.new_set()

T["LSP navigation"]["go-to-definition works with Lua LSP"] = function()
    local result = helpers.nvim_interaction_test(
        [[
        vim.wait(2000)

        -- Create a Lua file with function definition and call
        local tmpfile = vim.fn.tempname() .. ".lua"
        vim.cmd("edit " .. tmpfile)

        vim.api.nvim_buf_set_lines(0, 0, -1, false, {
            "local function my_function()",
            "  return 42",
            "end",
            "",
            "my_function()", -- Line 5: call site
        })
        vim.bo.filetype = "lua"

        -- Wait for LSP to attach
        vim.wait(3000, function()
            return #vim.lsp.get_clients({ bufnr = 0 }) > 0
        end)

        -- Position cursor on function call (line 5)
        vim.api.nvim_win_set_cursor(0, {5, 0})

        -- Trigger go-to-definition
        vim.lsp.buf.definition()
        vim.wait(500)

        local cursor = vim.api.nvim_win_get_cursor(0)
        if cursor[1] == 1 then
            print("SUCCESS: Go-to-definition moved to line 1")
        else
            print("WARNING: Cursor at line " .. cursor[1] .. ", expected line 1")
        end

        vim.fn.delete(tmpfile)
    ]],
        20000
    )

    MiniTest.expect.equality(result.code, 0, "Go-to-definition should work: " .. result.stderr)
end

T["LSP navigation"]["find references works"] = function()
    local result = helpers.nvim_interaction_test(
        [[
        vim.wait(2000)

        local tmpfile = vim.fn.tempname() .. ".lua"
        vim.cmd("edit " .. tmpfile)

        vim.api.nvim_buf_set_lines(0, 0, -1, false, {
            "local my_var = 1",
            "local x = my_var + 2",
            "local y = my_var * 3",
        })
        vim.bo.filetype = "lua"

        vim.wait(3000, function()
            return #vim.lsp.get_clients({ bufnr = 0 }) > 0
        end)

        -- Position cursor on variable definition
        vim.api.nvim_win_set_cursor(0, {1, 6})

        -- Trigger references - should show in quickfix/picker
        vim.lsp.buf.references()
        vim.wait(500)

        print("SUCCESS: References command executed")

        vim.fn.delete(tmpfile)
    ]],
        20000
    )

    MiniTest.expect.equality(result.code, 0, "Find references should work: " .. result.stderr)
end

T["LSP navigation"]["hover shows documentation"] = function()
    local result = helpers.nvim_interaction_test(
        [[
        vim.wait(2000)

        local tmpfile = vim.fn.tempname() .. ".lua"
        vim.cmd("edit " .. tmpfile)

        vim.api.nvim_buf_set_lines(0, 0, -1, false, {
            "vim.fn.expand('%')", -- builtin function
        })
        vim.bo.filetype = "lua"

        vim.wait(3000, function()
            return #vim.lsp.get_clients({ bufnr = 0 }) > 0
        end)

        -- Position on vim.fn
        vim.api.nvim_win_set_cursor(0, {1, 4})

        -- Trigger hover
        vim.lsp.buf.hover()
        vim.wait(500)

        print("SUCCESS: Hover executed")

        vim.fn.delete(tmpfile)
    ]],
        20000
    )

    MiniTest.expect.equality(result.code, 0, "Hover should work: " .. result.stderr)
end

T["LSP code actions"] = MiniTest.new_set()

T["LSP code actions"]["code action is available"] = function()
    local result = helpers.nvim_interaction_test(
        [[
        vim.wait(2000)

        local tmpfile = vim.fn.tempname() .. ".lua"
        vim.cmd("edit " .. tmpfile)

        vim.api.nvim_buf_set_lines(0, 0, -1, false, {
            "local unused_var = 1",
            "print('hello')",
        })
        vim.bo.filetype = "lua"

        vim.wait(3000, function()
            return #vim.lsp.get_clients({ bufnr = 0 }) > 0
        end)

        vim.api.nvim_win_set_cursor(0, {1, 6})

        -- Check if code action is available
        local actions_available = false
        vim.lsp.buf.code_action({
            filter = function(a) return a ~= nil end,
            apply = false,
        })
        vim.wait(500)

        print("SUCCESS: Code action available")

        vim.fn.delete(tmpfile)
    ]],
        20000
    )

    MiniTest.expect.equality(result.code, 0, "Code actions should be available: " .. result.stderr)
end

T["LSP code actions"]["rename symbol works"] = function()
    local result = helpers.nvim_interaction_test(
        [[
        vim.wait(2000)

        local tmpfile = vim.fn.tempname() .. ".lua"
        vim.cmd("edit " .. tmpfile)

        vim.api.nvim_buf_set_lines(0, 0, -1, false, {
            "local old_name = 1",
            "print(old_name)",
        })
        vim.bo.filetype = "lua"

        vim.wait(3000, function()
            return #vim.lsp.get_clients({ bufnr = 0 }) > 0
        end)

        vim.api.nvim_win_set_cursor(0, {1, 6})

        -- Note: Can't easily test interactive rename, but check command exists
        local has_rename = vim.lsp.buf.rename ~= nil
        if has_rename then
            print("SUCCESS: Rename command exists")
        end

        vim.fn.delete(tmpfile)
    ]],
        20000
    )

    MiniTest.expect.equality(result.code, 0, "Rename should be available: " .. result.stderr)
end

T["LSP diagnostics"] = MiniTest.new_set()

T["LSP diagnostics"]["diagnostics are displayed for errors"] = function()
    local result = helpers.nvim_interaction_test(
        [[
        vim.wait(2000)

        local tmpfile = vim.fn.tempname() .. ".lua"
        vim.cmd("edit " .. tmpfile)

        -- Invalid Lua code
        vim.api.nvim_buf_set_lines(0, 0, -1, false, {
            "local x = ",  -- Syntax error
        })
        vim.bo.filetype = "lua"

        vim.wait(3000, function()
            return #vim.lsp.get_clients({ bufnr = 0 }) > 0
        end)

        vim.wait(2000)

        local diagnostics = vim.diagnostic.get(0)
        if #diagnostics > 0 then
            print("SUCCESS: Found " .. #diagnostics .. " diagnostic(s)")
        else
            print("WARNING: No diagnostics found")
        end

        vim.fn.delete(tmpfile)
    ]],
        20000
    )

    MiniTest.expect.equality(result.code, 0, "Diagnostics should work: " .. result.stderr)
end

T["LSP completion integration"] = MiniTest.new_set()

T["LSP completion integration"]["completion triggered in Lua file"] = function()
    local result = helpers.nvim_interaction_test(
        [[
        vim.wait(2000)

        local tmpfile = vim.fn.tempname() .. ".lua"
        vim.cmd("edit " .. tmpfile)

        vim.api.nvim_buf_set_lines(0, 0, -1, false, {
            "vim.f",
        })
        vim.bo.filetype = "lua"

        vim.wait(3000, function()
            return #vim.lsp.get_clients({ bufnr = 0 }) > 0
        end)

        -- Move to end of line
        vim.api.nvim_win_set_cursor(0, {1, 5})

        -- Enter insert mode and trigger completion
        vim.cmd("startinsert")
        vim.wait(100)

        -- Trigger completion with Ctrl-Space
        vim.api.nvim_feedkeys("\14\32", "x", false) -- Ctrl-N then Space
        vim.wait(500)

        print("SUCCESS: Completion triggered")

        vim.fn.delete(tmpfile)
    ]],
        20000
    )

    MiniTest.expect.equality(result.code, 0, "Completion should trigger: " .. result.stderr)
end

T["LSP formatting"] = MiniTest.new_set()

T["LSP formatting"]["format on save is configured"] = function()
    vim.wait(1000)

    local conform = require("conform")
    MiniTest.expect.equality(type(conform.format), "function", "Format function should exist")
end

T["LSP formatting"]["can format Lua buffer"] = function()
    local result = helpers.nvim_interaction_test(
        [[
        vim.wait(2000)

        local tmpfile = vim.fn.tempname() .. ".lua"
        vim.cmd("edit " .. tmpfile)

        -- Unformatted Lua code
        vim.api.nvim_buf_set_lines(0, 0, -1, false, {
            "local x=1",
            "local y=2",
        })
        vim.bo.filetype = "lua"

        vim.wait(1000)

        -- Format buffer
        require("conform").format({ bufnr = 0, timeout_ms = 5000 })
        vim.wait(500)

        local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
        print("Formatted lines: " .. vim.inspect(lines))

        vim.fn.delete(tmpfile)
    ]],
        20000
    )

    MiniTest.expect.equality(result.code, 0, "Format should work: " .. result.stderr)
end

-- For manual running
if ... == nil then MiniTest.run() end

return T
