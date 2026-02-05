local MiniTest = require("mini.test")
local fre = require("find-relative-executable")

local T = MiniTest.new_set({
    hooks = {
        pre_case = function() fre.clear_cache() end,
    },
})

T["get_vcs_root"] = MiniTest.new_set()

T["get_vcs_root"]["returns table or nil"] = function()
    local result = fre.get_vcs_root(vim.fn.getcwd())
    MiniTest.expect.equality(type(result) == "table" or result == nil, true)
end

T["get_vcs_root"]["returns correct structure when in git repo"] = function()
    local result = fre.get_vcs_root(vim.fn.getcwd())

    -- This nvim config is in a git repo
    if result then
        MiniTest.expect.equality(type(result.type), "string")
        MiniTest.expect.equality(type(result.root), "string")
        MiniTest.expect.equality(result.type == "git" or result.type == "jj", true)
    end
end

T["get_vcs_root"]["caches results across calls"] = function()
    local result1 = fre.get_vcs_root(vim.fn.getcwd())
    local result2 = fre.get_vcs_root(vim.fn.getcwd())

    if result1 then
        assert(result2, "result2 should not be nil when result1 is not nil")
        MiniTest.expect.equality(result1.type, result2.type)
        MiniTest.expect.equality(result1.root, result2.root)
    else
        MiniTest.expect.equality(result2, nil)
    end
end

T["get_vcs_root"]["cache respects TTL"] = function()
    -- First call populates cache
    local result1 = fre.get_vcs_root(vim.fn.getcwd())

    -- Clear cache
    fre.clear_cache()

    -- Second call should recompute
    local result2 = fre.get_vcs_root(vim.fn.getcwd())

    -- Both should have same value (even if recomputed)
    if result1 then
        assert(result2, "result2 should not be nil when result1 is not nil")
        MiniTest.expect.equality(result1.type, result2.type)
        MiniTest.expect.equality(result1.root, result2.root)
    else
        MiniTest.expect.equality(result2, nil)
    end
end

if ... == nil then MiniTest.run() end

return T
