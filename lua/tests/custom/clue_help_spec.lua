local MiniTest = require("mini.test")
local _helpers = require("tests.helpers")
local clue_help = require("kyleking.utils.clue_help")

local T = MiniTest.new_set({ hooks = {} })

T["show"] = MiniTest.new_set()

T["show"]["accepts trigger string"] = function()
    -- Test that show() accepts a trigger without error
    -- Cannot easily test feedkeys behavior in headless mode, so verify API exists
    MiniTest.expect.equality(type(clue_help.show), "function")

    -- Verify it doesn't error on valid trigger
    local ok = pcall(clue_help.show, "g")
    MiniTest.expect.equality(ok, true)
end

T["show"]["handles special key notation"] = function()
    -- Verify special keys are handled without error
    local triggers = { "<C-w>", "<Leader>", "[", "]" }

    for _, trigger in ipairs(triggers) do
        local ok = pcall(clue_help.show, trigger)
        MiniTest.expect.equality(ok, true, "Failed on trigger: " .. trigger)
    end
end

T["show_menu"] = MiniTest.new_set()

T["show_menu"]["provides trigger menu"] = function()
    -- Verify show_menu function exists and is callable
    MiniTest.expect.equality(type(clue_help.show_menu), "function")

    -- In headless mode, vim.ui.select won't display, but we can verify it's called
    -- by mocking vim.ui.select
    local original_select = vim.ui.select
    local select_called = false
    local triggers_arg = nil

    vim.ui.select = function(items, _opts, _on_choice)
        select_called = true
        triggers_arg = items
        -- Don't call on_choice to avoid feedkeys in test
    end

    clue_help.show_menu()

    -- Restore original
    vim.ui.select = original_select

    MiniTest.expect.equality(select_called, true)
    MiniTest.expect.equality(type(triggers_arg), "table")
    MiniTest.expect.equality(#triggers_arg > 0, true)

    -- Verify trigger structure
    local first_trigger = triggers_arg[1]
    MiniTest.expect.equality(type(first_trigger.name), "string")
    MiniTest.expect.equality(type(first_trigger.keys), "string")
end

T["show_menu"]["includes expected triggers"] = function()
    local original_select = vim.ui.select
    local triggers_arg = nil

    vim.ui.select = function(items, _opts, _on_choice) triggers_arg = items end

    clue_help.show_menu()
    vim.ui.select = original_select

    -- Check for expected triggers
    local trigger_keys = vim.tbl_map(function(t) return t.keys end, triggers_arg)

    local expected_triggers = { "<C-w>", "[", "]", "g", "z", "'", "`", '"', "<Leader>" }

    for _, expected in ipairs(expected_triggers) do
        local found = vim.tbl_contains(trigger_keys, expected)
        MiniTest.expect.equality(found, true, "Missing trigger: " .. expected)
    end
end

if ... == nil then MiniTest.run() end

return T
