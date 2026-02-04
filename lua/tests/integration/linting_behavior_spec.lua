-- Test that linters produce real diagnostics on buggy code
-- Minimal integration test with fastest linter only
local MiniTest = require("mini.test")
local helpers = require("tests.helpers")

local T = MiniTest.new_set({
    hooks = {
        pre_case = function() end,
    },
})

T["linting integration"] = MiniTest.new_set()

T["linting integration"]["detects lint issues"] = function()
    if vim.fn.executable("selene") ~= 1 then
        MiniTest.skip("selene not installed")
        return
    end

    local result = helpers.nvim_interaction_test(
        [[
        vim.wait(500)

        local errors = {}
        local successes = {}

        local tmpdir = vim.fn.tempname()
        vim.fn.mkdir(tmpdir, "p")

        -- selene needs config to know about vim globals
        local selene_cfg = tmpdir .. "/selene.toml"
        local f = io.open(selene_cfg, "w")
        f:write('std = "vim"\n')
        f:close()
        local vim_toml = tmpdir .. "/vim.toml"
        f = io.open(vim_toml, "w")
        f:write('[selene]\nbase = "lua51"\nname = "vim"\n\n[vim]\nany = true\n')
        f:close()

        -- Test 1: Unused variable detection
        local tmpfile1 = tmpdir .. "/test_unused.lua"
        f = io.open(tmpfile1, "w")
        f:write("local unused_var = 42\nprint('hello')\n")
        f:close()

        vim.cmd("edit " .. tmpfile1)
        vim.wait(200)
        require("lint").try_lint({ "selene" })

        local found = vim.wait(2000, function()
            return #vim.diagnostic.get(0) > 0
        end, 100)

        if found then
            local diagnostics = vim.diagnostic.get(0)
            local has_unused = false
            for _, d in ipairs(diagnostics) do
                if d.message:match("unused") then
                    has_unused = true
                    break
                end
            end
            if has_unused then
                table.insert(successes, "unused variable")
            else
                table.insert(errors, "unused: diagnostics found but none about unused")
            end
        else
            table.insert(errors, "unused: no diagnostics produced")
        end

        vim.fn.delete(tmpdir, "rf")

        -- Report success
        if #successes > 0 then
            print("SUCCESS: selene detected " .. table.concat(successes, ", "))
        end
        if #errors > 0 then
            error("FAILURES: " .. table.concat(errors, "; "))
        end
    ]],
        10000
    )

    MiniTest.expect.equality(result.code, 0, "selene should detect lint issues:\n" .. result.stderr)
end

T["linting integration"]["nvim-lint is configured"] = function()
    helpers.wait_for_plugins()
    local lint = require("lint")
    MiniTest.expect.equality(type(lint.linters_by_ft), "table", "Linters should be configured")
end

-- For manual running
if ... == nil then MiniTest.run() end

return T
