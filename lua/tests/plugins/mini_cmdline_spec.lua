-- Test mini.cmdline integration
local MiniTest = require("mini.test")
local helpers = require("tests.helpers")

local T = MiniTest.new_set({
    hooks = {
        pre_case = function() helpers.wait_for_plugins() end,
    },
})

T["mini.cmdline"] = MiniTest.new_set()

T["mini.cmdline"]["autocomplete enabled"] = function()
    MiniTest.expect.equality(require("mini.cmdline").config.autocomplete.enable, true)
end

T["mini.cmdline"]["autocorrect enabled"] = function()
    MiniTest.expect.equality(require("mini.cmdline").config.autocorrect.enable, true)
end

T["mini.cmdline"]["autopeek enabled"] = function()
    MiniTest.expect.equality(require("mini.cmdline").config.autopeek.enable, true)
end

-- For manual running
if ... == nil then MiniTest.run() end

return T
