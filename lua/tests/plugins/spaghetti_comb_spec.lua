-- Test spaghetti-comb.nvim integration (local plugin from ~/Developer/kyleking)
local MiniTest = require("mini.test")
local helpers = require("tests.helpers")

local T = MiniTest.new_set({
    hooks = {
        pre_case = function()
            helpers.wait_for_plugins()
            require("spaghetti-comb.history.manager").clear_all_history()
        end,
    },
})

T["spaghetti-comb"] = MiniTest.new_set()

T["spaghetti-comb"]["records jumps and navigates back"] = function()
    local mgr = require("spaghetti-comb.history.manager")
    local first = { file_path = vim.fn.fnamemodify("lua/kyleking/pack.lua", ":p"), position = { line = 5, column = 1 } }
    local second = {
        file_path = vim.fn.fnamemodify("lua/kyleking/theme.lua", ":p"),
        position = { line = 3, column = 1 },
    }

    MiniTest.expect.equality(mgr.record_jump(nil, first, "manual"), true, "First jump should record")
    MiniTest.expect.equality(mgr.record_jump(first, second, "manual"), true, "Second jump should record")
    MiniTest.expect.equality(#mgr.get_all_entries(), 2, "Trail should hold both jumps")

    local ok, entry = mgr.go_back(1)
    MiniTest.expect.equality(ok, true, "go_back should succeed")
    MiniTest.expect.equality(vim.fn.fnamemodify(entry.file_path, ":t"), "pack.lua", "go_back should land on first jump")
end

T["spaghetti-comb"]["bookmark toggle adds then removes"] = function()
    local bookmarks = require("spaghetti-comb.history.bookmarks")
    local location = {
        file_path = vim.fn.fnamemodify("lua/kyleking/pack.lua", ":p"),
        position = { line = 10, column = 1 },
    }

    local ok, action = bookmarks.toggle_bookmark(location)
    MiniTest.expect.equality(ok, true, "First toggle should succeed")
    MiniTest.expect.equality(action, "added", "First toggle should add")

    ok, action = bookmarks.toggle_bookmark(location)
    MiniTest.expect.equality(ok, true, "Second toggle should succeed")
    MiniTest.expect.equality(action, "removed", "Second toggle should remove")
end

T["spaghetti-comb"]["tree toggle opens and closes floats"] = function()
    local mgr = require("spaghetti-comb.history.manager")
    local location = {
        file_path = vim.fn.fnamemodify("lua/kyleking/pack.lua", ":p"),
        position = { line = 5, column = 1 },
    }
    mgr.record_jump(nil, location, "manual")

    local function count_floats()
        local floats = 0
        for _, win in ipairs(vim.api.nvim_list_wins()) do
            if vim.api.nvim_win_get_config(win).relative ~= "" then floats = floats + 1 end
        end
        return floats
    end

    local baseline = count_floats()
    vim.cmd("SpaghettiCombTree")
    MiniTest.expect.equality(count_floats() > baseline, true, "Tree should open floating windows")
    vim.cmd("SpaghettiCombTree")
    MiniTest.expect.equality(count_floats(), baseline, "Second toggle should close them")
end

if ... == nil then MiniTest.run() end
return T
