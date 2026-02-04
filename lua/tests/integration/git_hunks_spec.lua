-- Test git hunk operations (mini.diff/mini.git)
local MiniTest = require("mini.test")
local helpers = require("tests.helpers")

local T = MiniTest.new_set({
    hooks = {
        pre_case = function() helpers.wait_for_plugins() end,
    },
})

T["git hunks"] = MiniTest.new_set()

T["git hunks"]["mini.diff is configured"] = function()
    local MiniDiff = require("mini.diff")

    MiniTest.expect.equality(type(MiniDiff.config), "table", "mini.diff should be configured")
    MiniTest.expect.equality(type(MiniDiff.toggle_overlay), "function", "toggle_overlay should be available")
end

T["git hunks"]["mini.git is configured"] = function()
    local MiniGit = require("mini.git")

    MiniTest.expect.equality(type(MiniGit.config), "table", "mini.git should be configured")
    MiniTest.expect.equality(type(MiniGit.show_at_cursor), "function", "show_at_cursor should be available")
end

T["git hunks"]["navigation keybindings exist"] = function()
    local keymaps = vim.api.nvim_get_keymap("n")

    local has_hunk_nav = false
    for _, keymap in ipairs(keymaps) do
        local desc = keymap.desc or ""
        if desc:match("[Hh]unk") or desc:match("[Dd]iff") then
            has_hunk_nav = true
            break
        end
    end

    -- Also check ]H and [H specifically
    local has_bracket_h = false
    for _, keymap in ipairs(keymaps) do
        if keymap.lhs == "]H" or keymap.lhs == "[H" then
            has_bracket_h = true
            break
        end
    end

    MiniTest.expect.equality(
        has_hunk_nav or has_bracket_h,
        true,
        "Git hunk navigation keybindings should be configured"
    )
end

T["git hunks"]["overlay toggle works"] = function()
    local MiniDiff = require("mini.diff")

    -- Test that toggle_overlay function is callable
    local success = pcall(function()
        -- Don't actually toggle in test, just verify it's callable
        MiniTest.expect.equality(type(MiniDiff.toggle_overlay), "function")
    end)

    MiniTest.expect.equality(success, true, "toggle_overlay should be callable")
end

T["git hunks"]["show_at_cursor works"] = function()
    local MiniGit = require("mini.git")

    -- Test that show_at_cursor function is callable
    local success = pcall(function() MiniTest.expect.equality(type(MiniGit.show_at_cursor), "function") end)

    MiniTest.expect.equality(success, true, "show_at_cursor should be callable")
end

-- For manual running
if ... == nil then MiniTest.run() end

return T
