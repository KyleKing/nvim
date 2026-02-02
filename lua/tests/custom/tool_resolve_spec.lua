local MiniTest = require("mini.test")
local fre = require("find-relative-executable")

local T = MiniTest.new_set({
    hooks = {
        pre_case = function() fre.clear_cache() end,
    },
})

T["find-relative-executable"] = MiniTest.new_set()

T["find-relative-executable"]["command_for returns a function"] = function()
    local cmd_fn = fre.command_for("ruff")
    MiniTest.expect.equality(type(cmd_fn), "function")
end

T["find-relative-executable"]["cmd_for returns a function"] = function()
    local cmd_fn = fre.cmd_for("oxlint")
    MiniTest.expect.equality(type(cmd_fn), "function")
end

T["find-relative-executable"]["resolve returns string for python tool"] = function()
    local result = fre.resolve("ruff", vim.fn.getcwd())
    MiniTest.expect.equality(type(result), "string")
end

T["find-relative-executable"]["resolve returns string for node tool"] = function()
    local result = fre.resolve("oxlint", vim.fn.getcwd())
    MiniTest.expect.equality(type(result), "string")
end

T["find-relative-executable"]["unknown tools fall back gracefully"] = function()
    local result = fre.resolve("nonexistent_tool_xyz", vim.fn.getcwd())
    MiniTest.expect.equality(type(result), "string")
end

T["find-relative-executable"]["clear_cache is callable without error"] = function()
    MiniTest.expect.no_error(function() fre.clear_cache() end)
end

if ... == nil then MiniTest.run() end

return T
