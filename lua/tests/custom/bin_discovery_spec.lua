-- Test kyleking.utils.bin_discovery module
local MiniTest = require("mini.test")
local helpers = require("tests.helpers")

local T = MiniTest.new_set({
    hooks = {
        pre_case = function()
            -- Clean up before each test
        end,
    },
})

T["bin_discovery"] = MiniTest.new_set()

T["bin_discovery"]["bin_discovery module loads without errors"] = function()
    MiniTest.expect.no_error(function() require("kyleking.utils.bin_discovery") end)
end

T["node_modules detection"] = MiniTest.new_set()

T["node_modules detection"]["detect_node_modules function exists"] = function()
    local bin_discovery = require("kyleking.utils.bin_discovery")
    MiniTest.expect.equality(
        type(bin_discovery.detect_node_modules),
        "function",
        "detect_node_modules should be a function"
    )
end

T["node_modules detection"]["detect_node_modules is callable"] = function()
    local bin_discovery = require("kyleking.utils.bin_discovery")

    -- Should not error when called
    MiniTest.expect.no_error(
        function() bin_discovery.detect_node_modules() end,
        "detect_node_modules should be callable"
    )
end

T["node_modules detection"]["autocmd is configured"] = function()
    -- Check that NodeModulesDetect autocmd exists
    local autocmds = vim.api.nvim_get_autocmds({ group = "NodeModulesDetect" })
    MiniTest.expect.equality(#autocmds > 0, true, "NodeModulesDetect autocmd should be configured")
end

T["node_modules detection"]["autocmd triggers on BufEnter"] = function()
    local autocmds = vim.api.nvim_get_autocmds({ group = "NodeModulesDetect", event = "BufEnter" })
    MiniTest.expect.equality(#autocmds > 0, true, "BufEnter autocmd should exist")
end

-- For manual running
if ... == nil then MiniTest.run() end

return T
