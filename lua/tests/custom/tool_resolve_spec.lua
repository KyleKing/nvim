local MiniTest = require("mini.test")

local T = MiniTest.new_set({
    hooks = {
        pre_case = function() require("find-relative-executable").clear_cache() end,
    },
})

T["find-relative-executable"] = MiniTest.new_set()

T["find-relative-executable"]["module loads without errors"] = function()
    MiniTest.expect.no_error(function() require("find-relative-executable") end)
end

T["find-relative-executable"]["resolve function exists"] = function()
    local mod = require("find-relative-executable")
    MiniTest.expect.equality(type(mod.resolve), "function", "resolve should be a function")
end

T["find-relative-executable"]["clear_cache function exists"] = function()
    local mod = require("find-relative-executable")
    MiniTest.expect.equality(type(mod.clear_cache), "function", "clear_cache should be a function")
end

T["find-relative-executable"]["command_for returns a function"] = function()
    local mod = require("find-relative-executable")
    local cmd_fn = mod.command_for("ruff")
    MiniTest.expect.equality(type(cmd_fn), "function", "command_for should return a function")
end

T["find-relative-executable"]["cmd_for returns a function"] = function()
    local mod = require("find-relative-executable")
    local cmd_fn = mod.cmd_for("oxlint")
    MiniTest.expect.equality(type(cmd_fn), "function", "cmd_for should return a function")
end

T["find-relative-executable"]["resolve returns string for python tool"] = function()
    local mod = require("find-relative-executable")
    local result = mod.resolve("ruff", vim.fn.getcwd())
    MiniTest.expect.equality(type(result), "string", "resolve should return a string for ruff")
end

T["find-relative-executable"]["resolve returns string for node tool"] = function()
    local mod = require("find-relative-executable")
    local result = mod.resolve("oxlint", vim.fn.getcwd())
    MiniTest.expect.equality(type(result), "string", "resolve should return a string for oxlint")
end

T["find-relative-executable"]["unknown tools fall back gracefully"] = function()
    local mod = require("find-relative-executable")
    local result = mod.resolve("nonexistent_tool_xyz", vim.fn.getcwd())
    MiniTest.expect.equality(type(result), "string", "resolve should return a string for unknown tools")
end

T["find-relative-executable"]["clear_cache is callable without error"] = function()
    local mod = require("find-relative-executable")
    MiniTest.expect.no_error(function() mod.clear_cache() end)
end

if ... == nil then MiniTest.run() end

return T
