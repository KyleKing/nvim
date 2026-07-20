-- Test mini.input integration
local MiniTest = require("mini.test")
local helpers = require("tests.helpers")

local T = MiniTest.new_set({
    hooks = {
        pre_case = function() helpers.wait_for_plugins() end,
    },
})

T["mini.input"] = MiniTest.new_set()

T["mini.input"]["overrides vim.ui.input"] = function()
    local MiniInput = require("mini.input")
    MiniTest.expect.equality(vim.ui.input, MiniInput.ui_input, "vim.ui.input should route through mini.input")
end

T["mini.input"]["default scope is editor"] = function()
    MiniTest.expect.equality(require("mini.input").config.scope, "editor")
end

-- For manual running
if ... == nil then MiniTest.run() end

return T
