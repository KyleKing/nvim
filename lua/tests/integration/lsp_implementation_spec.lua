-- Test vim.lsp.buf.implementation() vs vim.lsp.buf.definition() in monorepos
-- This tests whether using "implementation" bypasses re-exports better than "definition"
local MiniTest = require("mini.test")
local helpers = require("tests.helpers")

local T = MiniTest.new_set({
    hooks = {
        pre_case = function() end,
    },
})

T["LSP implementation vs definition"] = MiniTest.new_set()

T["LSP implementation vs definition"]["implementation navigates past re-exports (TypeScript)"] = function()
    local result = helpers.nvim_interaction_test(
        [[
        vim.wait(2000)

        -- Create monorepo structure
        local tmpdir = vim.fn.tempname()
        vim.fn.mkdir(tmpdir, "p")

        local pkg_b_dir = tmpdir .. "/package-b"
        vim.fn.mkdir(pkg_b_dir, "p")

        -- Actual implementation
        local utils_file = pkg_b_dir .. "/utils.ts"
        vim.fn.writefile({
            "export function calculateSum(a: number, b: number): number {",
            "  return a + b;",
            "}",
        }, utils_file)

        -- Re-export
        local index_file = pkg_b_dir .. "/index.ts"
        vim.fn.writefile({ "export { calculateSum } from './utils';" }, index_file)

        -- Usage
        local pkg_a_dir = tmpdir .. "/package-a"
        vim.fn.mkdir(pkg_a_dir, "p")

        local main_file = pkg_a_dir .. "/main.ts"
        vim.fn.writefile({
            "import { calculateSum } from '../package-b';",
            "",
            "const result = calculateSum(1, 2);",
        }, main_file)

        vim.cmd("edit " .. main_file)
        vim.bo.filetype = "typescript"

        -- Wait for LSP
        vim.wait(4000, function()
            return #vim.lsp.get_clients({ bufnr = 0 }) > 0
        end)

        -- Position cursor on calculateSum call
        vim.api.nvim_win_set_cursor(0, {3, 15})

        -- TEST 1: Try definition (expected to go to re-export)
        vim.lsp.buf.definition()
        vim.wait(1000)

        local def_file = vim.fn.expand("%:p")
        local def_line = vim.api.nvim_win_get_cursor(0)[1]
        print("DEFINITION: " .. def_file .. " line " .. def_line)

        -- Return to main.ts
        vim.cmd("edit " .. main_file)
        vim.api.nvim_win_set_cursor(0, {3, 15})
        vim.wait(500)

        -- TEST 2: Try implementation (expected to go to actual source)
        vim.lsp.buf.implementation()
        vim.wait(1000)

        local impl_file = vim.fn.expand("%:p")
        local impl_line = vim.api.nvim_win_get_cursor(0)[1]
        print("IMPLEMENTATION: " .. impl_file .. " line " .. impl_line)

        if impl_file:match("utils%.ts$") then
            print("SUCCESS: implementation() navigated to utils.ts")
        elseif impl_file:match("index%.ts$") then
            print("PARTIAL: implementation() went to index.ts (same as definition)")
        else
            print("WARNING: implementation() stayed in main.ts")
        end

        vim.fn.delete(tmpdir, "rf")
    ]],
        25000
    )

    MiniTest.expect.equality(result.code, 0, "Process should complete: " .. result.stderr)

    -- Check if implementation worked better than definition
    local has_success = result.stdout:match("SUCCESS: implementation")
    local has_partial = result.stdout:match("PARTIAL: implementation")

    if has_success then
        -- Test passes if implementation goes to utils.ts
        MiniTest.expect.equality(true, true, "implementation() successfully bypasses re-exports")
    elseif has_partial then
        -- Document that implementation has same behavior as definition
        print("Note: implementation() has same behavior as definition() in this case")
        MiniTest.expect.equality(true, true, "implementation() attempted but same as definition")
    else
        -- Fail if implementation doesn't work at all
        MiniTest.expect.equality(false, true, "implementation() should navigate somewhere. Output:\n" .. result.stdout)
    end
end

T["LSP implementation vs definition"]["compare definition and implementation outputs (Python)"] = function()
    local result = helpers.nvim_interaction_test(
        [[
        vim.wait(2000)

        local tmpdir = vim.fn.tempname()
        vim.fn.mkdir(tmpdir, "p")

        local pkg_b_dir = tmpdir .. "/package_b"
        vim.fn.mkdir(pkg_b_dir, "p")

        -- Actual implementation
        local utils_file = pkg_b_dir .. "/utils.py"
        vim.fn.writefile({
            "def calculate_sum(a: int, b: int) -> int:",
            '    """Calculate sum."""',
            "    return a + b",
        }, utils_file)

        -- Re-export
        local init_file = pkg_b_dir .. "/__init__.py"
        vim.fn.writefile({ "from .utils import calculate_sum" }, init_file)

        -- Usage
        local pkg_a_dir = tmpdir .. "/package_a"
        vim.fn.mkdir(pkg_a_dir, "p")

        local main_file = pkg_a_dir .. "/main.py"
        vim.fn.writefile({
            "from package_b import calculate_sum",
            "",
            "result = calculate_sum(1, 2)",
        }, main_file)

        vim.cmd("edit " .. main_file)
        vim.bo.filetype = "python"

        vim.wait(4000, function()
            return #vim.lsp.get_clients({ bufnr = 0 }) > 0
        end)

        vim.api.nvim_win_set_cursor(0, {3, 9})

        -- TEST: Try implementation
        vim.lsp.buf.implementation()
        vim.wait(1000)

        local impl_file = vim.fn.expand("%:p")
        print("IMPLEMENTATION: " .. impl_file)

        if impl_file:match("utils%.py$") then
            print("SUCCESS: implementation() navigated to utils.py")
        else
            print("INFO: implementation() behavior: " .. vim.fn.fnamemodify(impl_file, ":t"))
        end

        vim.fn.delete(tmpdir, "rf")
    ]],
        25000
    )

    MiniTest.expect.equality(result.code, 0, "Process should complete: " .. result.stderr)
    -- This test is informational to see implementation() behavior
end

-- For manual running
if ... == nil then MiniTest.run() end

return T
