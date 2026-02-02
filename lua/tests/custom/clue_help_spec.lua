-- Test clue help system
local MiniTest = require("mini.test")
local helpers = require("tests.helpers")

local T = MiniTest.new_set({
    hooks = {
        pre_case = function()
            -- Clean up before each test
        end,
    },
})

T["clue_help module"] = MiniTest.new_set()

T["clue_help module"]["module can be required"] = function()
    local success, clue_help = pcall(require, "kyleking.utils.clue_help")
    MiniTest.expect.equality(success, true, "clue_help module should load without error")
    MiniTest.expect.equality(type(clue_help), "table", "clue_help should be a table")
end

T["clue_help module"]["has show function"] = function()
    local clue_help = require("kyleking.utils.clue_help")
    MiniTest.expect.equality(type(clue_help.show), "function", "clue_help.show should be a function")
end

T["clue_help module"]["has show_menu function"] = function()
    local clue_help = require("kyleking.utils.clue_help")
    MiniTest.expect.equality(type(clue_help.show_menu), "function", "clue_help.show_menu should be a function")
end

T["keymaps"] = MiniTest.new_set()

T["keymaps"]["<Leader>? keymap exists"] = function()
    helpers.wait_for_plugins()

    local keymap = vim.fn.maparg("<Leader>?", "n", false, true)
    MiniTest.expect.equality(type(keymap), "table", "<Leader>? mapping should exist")
    MiniTest.expect.equality(keymap.desc, "Show clue help menu", "Should have correct description")
end

T["keymaps"]["<Leader>?w keymap exists"] = function()
    helpers.wait_for_plugins()

    local keymap = vim.fn.maparg("<Leader>?w", "n", false, true)
    MiniTest.expect.equality(type(keymap), "table", "<Leader>?w mapping should exist")
    MiniTest.expect.equality(keymap.desc, "Window commands (<C-w>)", "Should show window commands description")
end

T["keymaps"]["<Leader>?[ keymap exists"] = function()
    helpers.wait_for_plugins()

    local keymap = vim.fn.maparg("<Leader>?[", "n", false, true)
    MiniTest.expect.equality(type(keymap), "table", "<Leader>?[ mapping should exist")
end

T["keymaps"]["<Leader>?g keymap exists"] = function()
    helpers.wait_for_plugins()

    local keymap = vim.fn.maparg("<Leader>?g", "n", false, true)
    MiniTest.expect.equality(type(keymap), "table", "<Leader>?g mapping should exist")
    MiniTest.expect.equality(keymap.desc, "g commands", "Should show g commands description")
end

-- For manual running
if ... == nil then MiniTest.run() end

return T
