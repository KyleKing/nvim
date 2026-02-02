local MiniTest = require("mini.test")

local T = MiniTest.new_set({
    hooks = {
        pre_case = function() end,
    },
})

T["noqa"] = MiniTest.new_set()

T["noqa"]["module loads without errors"] = function()
    MiniTest.expect.no_error(function() require("kyleking.utils.noqa") end)
end

T["noqa"]["ignore_inline function exists"] = function()
    local mod = require("kyleking.utils.noqa")
    MiniTest.expect.equality(type(mod.ignore_inline), "function", "ignore_inline should be a function")
end

T["noqa"]["ignore_file function exists"] = function()
    local mod = require("kyleking.utils.noqa")
    MiniTest.expect.equality(type(mod.ignore_file), "function", "ignore_file should be a function")
end

T["noqa"]["tool configs cover expected tools"] = function()
    local mod = require("kyleking.utils.noqa")
    local configs = mod._tool_configs

    local expected = { "golangcilint", "oxlint", "pyright", "ruff", "selene", "shellcheck", "stylelint", "yamllint" }
    for _, tool in ipairs(expected) do
        MiniTest.expect.equality(configs[tool] ~= nil, true, tool .. " should have a tool config")
    end
end

T["noqa"]["tool config templates are callable"] = function()
    local mod = require("kyleking.utils.noqa")
    local configs = mod._tool_configs

    for name, config in pairs(configs) do
        MiniTest.expect.equality(type(config.template), "function", name .. " template should be a function")
        local result = config.template("TEST001")
        MiniTest.expect.equality(type(result), "string", name .. " template should return a string")
    end
end

if ... == nil then MiniTest.run() end

return T
