-- Test LSP-related plugins (lsp_signature, nvim-lint, lazydev)
local MiniTest = require("mini.test")
local helpers = require("tests.helpers")

local T = MiniTest.new_set({
    hooks = {
        pre_case = function() helpers.wait_for_plugins() end,
    },
})

-- Behavioral tests for diagnostics formatting
T["diagnostics"] = MiniTest.new_set()

T["diagnostics"]["diagnostic config has format function"] = function()
    local config = vim.diagnostic.config()
    MiniTest.expect.equality(type(config.virtual_text.format), "function", "virtual_text should have a format function")
    MiniTest.expect.equality(type(config.float.format), "function", "float should have a format function")
end

T["diagnostics"]["format function includes source and code"] = function()
    local config = vim.diagnostic.config()
    local format_fn = config.virtual_text.format

    local result = format_fn({ source = "ruff", code = "E501", message = "line too long" })
    MiniTest.expect.equality(result, "[ruff E501] line too long", "format should include source and code prefix")
end

T["diagnostics"]["format function handles missing source and code"] = function()
    local config = vim.diagnostic.config()
    local format_fn = config.virtual_text.format

    local result = format_fn({ message = "some error" })
    MiniTest.expect.equality(result, "some error", "format should work without source/code")
end

-- For manual running
if ... == nil then MiniTest.run() end

return T
