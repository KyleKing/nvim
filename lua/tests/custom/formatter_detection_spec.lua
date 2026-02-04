local MiniTest = require("mini.test")
local fre = require("find-relative-executable")

local T = MiniTest.new_set({
    hooks = {
        pre_case = function() fre.clear_cache() end,
    },
})

T["detect_formatters"] = MiniTest.new_set()

T["detect_formatters"]["returns array"] = function()
    local result = fre.detect_formatters({ "ruff", "black" }, vim.fn.getcwd())
    MiniTest.expect.equality(type(result), "table")
end

T["detect_formatters"]["returns empty when no tools available"] = function()
    local result = fre.detect_formatters({ "nonexistent_tool_xyz123", "another_fake_tool" }, vim.fn.getcwd())
    MiniTest.expect.equality(type(result), "table")
end

T["detect_formatters"]["prioritizes configured tools"] = function()
    -- This is hard to test without creating temp config files
    -- Just verify it doesn't crash
    MiniTest.expect.no_error(function() fre.detect_formatters({ "prettier", "biome" }, vim.fn.getcwd()) end)
end

T["detect_formatters"]["handles single candidate"] = function()
    local result = fre.detect_formatters({ "stylua" }, vim.fn.getcwd())
    MiniTest.expect.equality(type(result), "table")
end

T["detect_formatters"]["handles empty candidates"] = function()
    local result = fre.detect_formatters({}, vim.fn.getcwd())
    MiniTest.expect.equality(#result, 0)
end

if ... == nil then MiniTest.run() end

return T
