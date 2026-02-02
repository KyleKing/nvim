local MiniTest = require("mini.test")
local constants = require("kyleking.utils.constants")

local T = MiniTest.new_set({ hooks = {} })

T["should_ignore"] = MiniTest.new_set()

T["should_ignore"]["ignores common paths"] = function()
    MiniTest.expect.equality(constants.should_ignore(".DS_Store"), true)
    MiniTest.expect.equality(constants.should_ignore(".git"), true)
    MiniTest.expect.equality(constants.should_ignore("__pycache__"), true)
    MiniTest.expect.equality(constants.should_ignore("node_modules"), true)
    MiniTest.expect.equality(constants.should_ignore(".venv"), true)
end

T["should_ignore"]["allows normal paths"] = function()
    MiniTest.expect.equality(constants.should_ignore("README.md"), false)
    MiniTest.expect.equality(constants.should_ignore("src"), false)
    MiniTest.expect.equality(constants.should_ignore("main.lua"), false)
    MiniTest.expect.equality(constants.should_ignore("init.lua"), false)
end

if MiniTest.current.all_cases == nil then MiniTest.run() end

return T
