local MiniTest = require("mini.test")
local noqa = require("kyleking.utils.noqa")

local T = MiniTest.new_set({ hooks = {} })

T["tool configs"] = MiniTest.new_set()

T["tool configs"]["all expected tools configured"] = function()
    local expected = { "golangcilint", "oxlint", "pyright", "ruff", "selene", "shellcheck", "stylelint", "yamllint" }
    for _, tool in ipairs(expected) do
        MiniTest.expect.equality(noqa._tool_configs[tool] ~= nil, true, tool)
    end
end

T["tool configs"]["templates generate valid output"] = function()
    for name, config in pairs(noqa._tool_configs) do
        local result = config.template("TEST001")
        MiniTest.expect.equality(type(result), "string", name)
        MiniTest.expect.equality(#result > 0, true, name .. " should generate non-empty string")
    end
end

if ... == nil then MiniTest.run() end

return T
