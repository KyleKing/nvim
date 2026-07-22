-- Test Python development workflow
local MiniTest = require("mini.test")
local helpers = require("tests.helpers")

local T = MiniTest.new_set({
    hooks = {
        pre_case = function()
            -- Clean up before each test
        end,
    },
})

T["python workflow"] = MiniTest.new_set()

T["python workflow"]["can create python buffer"] = function()
    local bufnr = helpers.create_test_buffer({ "def hello():", "    pass" }, "python")
    MiniTest.expect.equality(vim.api.nvim_buf_is_valid(bufnr), true, "Python buffer should be valid")
    MiniTest.expect.equality(vim.bo[bufnr].filetype, "python", "Filetype should be python")
    helpers.delete_buffer(bufnr)
end

T["python workflow"]["python formatter is configured"] = function()
    helpers.wait_for_plugins()

    local conform = require("conform")
    -- Python picks its formatters from the project, so the entry is a callable
    local entry = conform.formatters_by_ft.python or {}
    local formatters = vim.is_callable(entry) and entry(vim.api.nvim_get_current_buf()) or entry

    MiniTest.expect.equality(#formatters > 0, true, "Python should have formatters configured")

    local has_ruff = false
    for _, formatter in ipairs(formatters) do
        if formatter:match("ruff") then
            has_ruff = true
            break
        end
    end

    MiniTest.expect.equality(has_ruff, true, "Python should use ruff formatter")
end

T["python workflow"]["python linter is configured"] = function()
    helpers.wait_for_plugins()

    local lint = require("lint")
    local linters = lint.linters_by_ft.python or {}

    MiniTest.expect.equality(#linters > 0, true, "Python should have linters configured")

    local has_ruff = false
    for _, linter in ipairs(linters) do
        if linter == "ruff" then
            has_ruff = true
            break
        end
    end

    MiniTest.expect.equality(has_ruff, true, "Python should use ruff linter")
end

T["python workflow"]["python parser is available"] = function()
    helpers.wait_for_plugins()

    -- nvim-treesitter's main branch dropped parsers.has_parser; ask the core API instead
    local has_parser = pcall(vim.treesitter.language.add, "python")

    MiniTest.expect.equality(has_parser, true, "Python parser should be installed")
end

T["python workflow"]["can detect python path"] = function()
    local fs_utils = require("kyleking.utils.fs_utils")
    local python_path = fs_utils.get_python_path()

    MiniTest.expect.equality(type(python_path), "string", "Should return python path")
    MiniTest.expect.equality(#python_path > 0, true, "Python path should not be empty")
end

-- For manual running
if ... == nil then MiniTest.run() end

return T
