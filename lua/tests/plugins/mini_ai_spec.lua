-- Test mini.ai integration
local MiniTest = require("mini.test")
local helpers = require("tests.helpers")

local T = MiniTest.new_set({
    hooks = {
        pre_case = function() helpers.wait_for_plugins() end,
    },
})

-- Config validation tests (behavioral tests migrated to docs/ai.lua)
T["mini.ai"] = MiniTest.new_set()

T["mini.ai"]["n_lines config is respected"] = function()
    local MiniAi = require("mini.ai")
    MiniTest.expect.equality(MiniAi.config.n_lines, 500, "n_lines should be set to 500")
end

T["mini.ai"]["search_method config is set"] = function()
    local MiniAi = require("mini.ai")
    MiniTest.expect.equality(MiniAi.config.search_method, "cover_or_next", "search_method should be 'cover_or_next'")
end

-- For manual running
if ... == nil then MiniTest.run() end

return T
