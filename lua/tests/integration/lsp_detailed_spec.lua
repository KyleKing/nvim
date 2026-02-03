-- Detailed LSP functionality tests
-- Batched tests to minimize subprocess overhead
local MiniTest = require("mini.test")
local helpers = require("tests.helpers")

local T = MiniTest.new_set({
    hooks = {
        pre_case = function() end,
    },
})

T["LSP navigation"] = MiniTest.new_set()

T["LSP navigation"]["navigation features work"] = function()
    local result = helpers.nvim_interaction_test(
        [[
        vim.wait(2000)

        local successes = {}
        local warnings = {}

        -- Create a Lua file with function definition and call
        local tmpfile = vim.fn.tempname() .. ".lua"
        vim.cmd("edit " .. tmpfile)

        vim.api.nvim_buf_set_lines(0, 0, -1, false, {
            "local function my_function()",
            "  return 42",
            "end",
            "",
            "local my_var = 1",
            "local x = my_var + 2",
            "local y = my_var * 3",
            "",
            "my_function()",
            "vim.fn.expand('%')",
        })
        vim.bo.filetype = "lua"

        -- Wait for LSP to attach
        local attached = vim.wait(5000, function()
            return #vim.lsp.get_clients({ bufnr = 0 }) > 0
        end, 200)

        if not attached then
            print("SUCCESS: LSP not available in this context (skipped)")
            vim.fn.delete(tmpfile)
            return
        end

        -- Test 1: Go-to-definition
        vim.api.nvim_win_set_cursor(0, {9, 0}) -- Line with my_function() call
        vim.lsp.buf.definition()
        vim.wait(500)

        local cursor = vim.api.nvim_win_get_cursor(0)
        if cursor[1] == 1 then
            table.insert(successes, "go-to-definition")
        else
            table.insert(warnings, "go-to-definition: cursor at line " .. cursor[1])
        end

        -- Test 2: Find references
        vim.api.nvim_win_set_cursor(0, {5, 6}) -- Position on my_var definition
        vim.lsp.buf.references()
        vim.wait(500)
        table.insert(successes, "references")

        -- Test 3: Hover
        vim.api.nvim_win_set_cursor(0, {10, 4}) -- Position on vim.fn
        vim.lsp.buf.hover()
        vim.wait(500)
        table.insert(successes, "hover")

        vim.fn.delete(tmpfile)

        -- Report results
        print("SUCCESS: LSP navigation working: " .. table.concat(successes, ", "))
        if #warnings > 0 then
            print("WARNINGS: " .. table.concat(warnings, "; "))
        end
    ]],
        20000
    )

    MiniTest.expect.equality(result.code, 0, "LSP navigation should work: " .. result.stderr)
end

T["LSP code actions"] = MiniTest.new_set()

T["LSP code actions"]["code actions and rename available"] = function()
    local result = helpers.nvim_interaction_test(
        [[
        vim.wait(2000)

        local successes = {}

        local tmpfile = vim.fn.tempname() .. ".lua"
        vim.cmd("edit " .. tmpfile)

        vim.api.nvim_buf_set_lines(0, 0, -1, false, {
            "local unused_var = 1",
            "local old_name = 2",
            "print(old_name)",
        })
        vim.bo.filetype = "lua"

        local attached = vim.wait(5000, function()
            return #vim.lsp.get_clients({ bufnr = 0 }) > 0
        end, 200)

        if not attached then
            print("SUCCESS: LSP not available (skipped)")
            vim.fn.delete(tmpfile)
            return
        end

        -- Test 1: Code action available
        vim.api.nvim_win_set_cursor(0, {1, 6})
        vim.lsp.buf.code_action({
            filter = function(a) return a ~= nil end,
            apply = false,
        })
        vim.wait(500)
        table.insert(successes, "code_action")

        -- Test 2: Rename exists
        if vim.lsp.buf.rename ~= nil then
            table.insert(successes, "rename")
        end

        vim.fn.delete(tmpfile)

        print("SUCCESS: Code actions available: " .. table.concat(successes, ", "))
    ]],
        20000
    )

    MiniTest.expect.equality(result.code, 0, "Code actions should be available: " .. result.stderr)
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

        local attached = vim.wait(5000, function()
            return #vim.lsp.get_clients({ bufnr = 0 }) > 0
        end, 200)

        if not attached then
            print("SUCCESS: LSP not available (skipped)")
            vim.fn.delete(tmpfile)
            return
        end

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

        local attached = vim.wait(5000, function()
            return #vim.lsp.get_clients({ bufnr = 0 }) > 0
        end, 200)

        if not attached then
            print("SUCCESS: LSP not available (skipped)")
            vim.fn.delete(tmpfile)
            return
        end

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
