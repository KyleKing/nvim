-- Tests for LSP go-to-definition behavior in monorepo scenarios
-- RED TEST: Demonstrates issue where gd goes to import instead of actual definition
local MiniTest = require("mini.test")
local helpers = require("tests.helpers")

local T = MiniTest.new_set({
    hooks = {
        pre_case = function() end,
    },
})

T["Monorepo go-to-definition"] = MiniTest.new_set()

T["Monorepo go-to-definition"]["gd navigates to actual source, not just import (Python)"] = function()
    local result = helpers.nvim_interaction_test(
        [[
        vim.wait(2000)

        -- Create a monorepo-like structure:
        -- package_b/utils.py - actual implementation
        -- package_b/__init__.py - re-exports from utils
        -- package_a/main.py - imports from package_b

        local tmpdir = vim.fn.tempname()
        vim.fn.mkdir(tmpdir, "p")

        -- Create package_b structure
        local pkg_b_dir = tmpdir .. "/package_b"
        vim.fn.mkdir(pkg_b_dir, "p")

        -- Actual implementation in utils.py
        local utils_file = pkg_b_dir .. "/utils.py"
        local utils_content = table.concat({
            "def calculate_sum(a: int, b: int) -> int:",
            "    \"\"\"Calculate sum of two numbers.\"\"\"",
            "    return a + b",
        }, "\n")
        vim.fn.writefile(vim.split(utils_content, "\n"), utils_file)

        -- Re-export in __init__.py
        local init_file = pkg_b_dir .. "/__init__.py"
        local init_content = "from .utils import calculate_sum"
        vim.fn.writefile(vim.split(init_content, "\n"), init_file)

        -- Create package_a that imports from package_b
        local pkg_a_dir = tmpdir .. "/package_a"
        vim.fn.mkdir(pkg_a_dir, "p")

        local main_file = pkg_a_dir .. "/main.py"
        local main_content = table.concat({
            "from package_b import calculate_sum",
            "",
            "result = calculate_sum(1, 2)",
        }, "\n")
        vim.fn.writefile(vim.split(main_content, "\n"), main_file)

        -- Open main.py and position cursor on calculate_sum usage
        vim.cmd("edit " .. main_file)
        vim.bo.filetype = "python"

        -- Wait for LSP to attach
        vim.wait(4000, function()
            return #vim.lsp.get_clients({ bufnr = 0 }) > 0
        end)

        -- Position cursor on calculate_sum in the function call (line 3)
        vim.api.nvim_win_set_cursor(0, {3, 9})

        -- Execute go-to-definition
        vim.lsp.buf.definition()
        vim.wait(1000)

        -- Check where we ended up
        local final_file = vim.fn.expand("%:p")
        local cursor = vim.api.nvim_win_get_cursor(0)

        print("Final file: " .. final_file)
        print("Final cursor position: line " .. cursor[1] .. ", col " .. cursor[2])

        -- RED TEST: This should go to utils.py line 1 (def calculate_sum)
        -- But it likely goes to __init__.py line 1 (from .utils import calculate_sum)
        if final_file:match("utils%.py$") and cursor[1] == 1 then
            print("SUCCESS: Navigated to actual definition in utils.py")
        elseif final_file:match("__init__%.py$") then
            print("EXPECTED FAILURE: Navigated to __init__.py (import) instead of utils.py (definition)")
        else
            print("WARNING: Unexpected navigation target")
        end

        -- Cleanup
        vim.fn.delete(tmpdir, "rf")
    ]],
        25000
    )

    -- This test is expected to fail initially (red test)
    -- It demonstrates the problem where gd goes to import instead of actual source
    MiniTest.expect.equality(result.code, 0, "Process should complete: " .. result.stderr)

    -- The actual assertion we want to pass eventually:
    -- We want output to contain "SUCCESS: Navigated to actual definition in utils.py"
    -- But currently it will likely say "EXPECTED FAILURE"
    local has_success = result.stdout:match("SUCCESS: Navigated to actual definition")
    MiniTest.expect.equality(
        has_success ~= nil,
        true,
        "Should navigate to actual definition, not import. Output:\n" .. result.stdout
    )
end

T["Monorepo go-to-definition"]["gd navigates to actual source, not just import (TypeScript)"] = function()
    local result = helpers.nvim_interaction_test(
        [[
        vim.wait(2000)

        -- Create a monorepo-like structure for TypeScript:
        -- package-b/utils.ts - actual implementation
        -- package-b/index.ts - re-exports from utils
        -- package-a/main.ts - imports from package-b

        local tmpdir = vim.fn.tempname()
        vim.fn.mkdir(tmpdir, "p")

        -- Create package-b structure
        local pkg_b_dir = tmpdir .. "/package-b"
        vim.fn.mkdir(pkg_b_dir, "p")

        -- Actual implementation in utils.ts
        local utils_file = pkg_b_dir .. "/utils.ts"
        local utils_content = table.concat({
            "export function calculateSum(a: number, b: number): number {",
            "  return a + b;",
            "}",
        }, "\n")
        vim.fn.writefile(vim.split(utils_content, "\n"), utils_file)

        -- Re-export in index.ts
        local index_file = pkg_b_dir .. "/index.ts"
        local index_content = "export { calculateSum } from './utils';"
        vim.fn.writefile(vim.split(index_content, "\n"), index_file)

        -- Create package-a that imports from package-b
        local pkg_a_dir = tmpdir .. "/package-a"
        vim.fn.mkdir(pkg_a_dir, "p")

        local main_file = pkg_a_dir .. "/main.ts"
        local main_content = table.concat({
            "import { calculateSum } from '../package-b';",
            "",
            "const result = calculateSum(1, 2);",
        }, "\n")
        vim.fn.writefile(vim.split(main_content, "\n"), main_file)

        -- Open main.ts and position cursor on calculateSum usage
        vim.cmd("edit " .. main_file)
        vim.bo.filetype = "typescript"

        -- Wait for LSP to attach
        vim.wait(4000, function()
            return #vim.lsp.get_clients({ bufnr = 0 }) > 0
        end)

        -- Position cursor on calculateSum in the function call (line 3)
        vim.api.nvim_win_set_cursor(0, {3, 15})

        -- Execute go-to-definition
        vim.lsp.buf.definition()
        vim.wait(1000)

        -- Check where we ended up
        local final_file = vim.fn.expand("%:p")
        local cursor = vim.api.nvim_win_get_cursor(0)

        print("Final file: " .. final_file)
        print("Final cursor position: line " .. cursor[1] .. ", col " .. cursor[2])

        -- RED TEST: This should go to utils.ts line 1 (export function calculateSum)
        -- But it likely goes to index.ts line 1 (export { calculateSum })
        if final_file:match("utils%.ts$") and cursor[1] == 1 then
            print("SUCCESS: Navigated to actual definition in utils.ts")
        elseif final_file:match("index%.ts$") then
            print("EXPECTED FAILURE: Navigated to index.ts (re-export) instead of utils.ts (definition)")
        else
            print("WARNING: Unexpected navigation target")
        end

        -- Cleanup
        vim.fn.delete(tmpdir, "rf")
    ]],
        25000
    )

    -- This test is expected to fail initially (red test)
    MiniTest.expect.equality(result.code, 0, "Process should complete: " .. result.stderr)

    local has_success = result.stdout:match("SUCCESS: Navigated to actual definition")
    MiniTest.expect.equality(
        has_success ~= nil,
        true,
        "Should navigate to actual definition, not re-export. Output:\n" .. result.stdout
    )
end

-- For manual running
if ... == nil then MiniTest.run() end

return T
