-- Test mini.clue integration
local MiniTest = require("mini.test")
local helpers = require("tests.helpers")

local T = MiniTest.new_set({
    hooks = {
        pre_case = function()
            -- Clean up before each test
        end,
    },
})

T["mini.clue"] = MiniTest.new_set()

T["mini.clue"]["keybinding module loads without errors"] = function()
    MiniTest.expect.no_error(function() require("kyleking.deps.keybinding") end)
end

T["mini.clue"]["mini.clue is configured"] = function()
    -- Wait for later() to execute
    vim.wait(1000)
    MiniTest.expect.equality(helpers.is_plugin_loaded("mini.clue"), true, "mini.clue should be loaded")
end

T["clue configuration"] = MiniTest.new_set()

T["clue configuration"]["leader triggers are configured"] = function()
    vim.wait(1000)

    local MiniClue = require("mini.clue")
    local config = MiniClue.config

    -- Check that triggers include leader
    local has_leader_trigger = false
    for _, trigger in ipairs(config.triggers) do
        if trigger.keys == "<Leader>" and trigger.mode == "n" then
            has_leader_trigger = true
            break
        end
    end

    MiniTest.expect.equality(has_leader_trigger, true, "Leader trigger should be configured")
end

T["clue configuration"]["built-in triggers are configured"] = function()
    vim.wait(1000)

    local MiniClue = require("mini.clue")
    local config = MiniClue.config

    -- Check for common triggers
    local trigger_keys = {}
    for _, trigger in ipairs(config.triggers) do
        trigger_keys[trigger.keys] = true
    end

    local expected_triggers = { "g", "'", "`", '"', "<C-w>", "z", "[", "]" }
    for _, key in ipairs(expected_triggers) do
        MiniTest.expect.equality(trigger_keys[key] ~= nil, true, "Trigger should exist: " .. key)
    end
end

T["clue configuration"]["window config has delay"] = function()
    vim.wait(1000)

    local MiniClue = require("mini.clue")
    local config = MiniClue.config

    MiniTest.expect.equality(type(config.window.delay), "number", "Window delay should be a number")
    MiniTest.expect.equality(config.window.delay, 500, "Window delay should be 500ms")
end

T["clue configuration"]["window has rounded border"] = function()
    vim.wait(1000)

    local MiniClue = require("mini.clue")
    local config = MiniClue.config

    MiniTest.expect.equality(config.window.config.border, "rounded", "Window should have rounded border")
end

T["group descriptions"] = MiniTest.new_set()

T["group descriptions"]["leader groups are defined"] = function()
    vim.wait(1000)

    local MiniClue = require("mini.clue")
    local config = MiniClue.config

    -- Check that clues include group descriptions
    local groups = {}
    for _, clue in ipairs(config.clues) do
        if type(clue) == "table" and clue.desc and clue.desc:match("^%+") then groups[clue.keys] = clue.desc end
    end

    -- Expected groups
    local expected_groups = {
        ["<Leader>S"] = "+Session",
        ["<Leader>b"] = "+Buffer",
        ["<Leader>f"] = "+Find",
        ["<Leader>g"] = "+Git",
        ["<Leader>l"] = "+LSP",
        ["<Leader>t"] = "+Terminal/Test",
        ["<Leader>u"] = "+UI",
    }

    for keys, expected_desc in pairs(expected_groups) do
        MiniTest.expect.equality(groups[keys], expected_desc, "Group should exist: " .. keys)
    end
end

T["group descriptions"]["LSP subgroups are defined"] = function()
    vim.wait(1000)

    local MiniClue = require("mini.clue")
    local config = MiniClue.config

    local groups = {}
    for _, clue in ipairs(config.clues) do
        if type(clue) == "table" and clue.desc and clue.desc:match("^%+") then groups[clue.keys] = clue.desc end
    end

    MiniTest.expect.equality(groups["<Leader>lg"], "+LSP Go to", "LSP Go to group should exist")
    MiniTest.expect.equality(groups["<Leader>lw"], "+Workspace", "Workspace group should exist")
end

T["group descriptions"]["UI subgroups are defined"] = function()
    vim.wait(1000)

    local MiniClue = require("mini.clue")
    local config = MiniClue.config

    local groups = {}
    for _, clue in ipairs(config.clues) do
        if type(clue) == "table" and clue.desc and clue.desc:match("^%+") then groups[clue.keys] = clue.desc end
    end

    MiniTest.expect.equality(groups["<Leader>uc"], "+Color", "Color group should exist")
    MiniTest.expect.equality(groups["<Leader>ug"], "+Git", "Git UI group should exist")
end

T["builtin clue generators"] = MiniTest.new_set()

T["builtin clue generators"]["builtin completion clues are included"] = function()
    vim.wait(1000)

    local MiniClue = require("mini.clue")
    local config = MiniClue.config

    -- Check for <C-x> trigger for completion
    local has_completion_trigger = false
    for _, trigger in ipairs(config.triggers) do
        if trigger.keys == "<C-x>" and trigger.mode == "i" then
            has_completion_trigger = true
            break
        end
    end

    MiniTest.expect.equality(has_completion_trigger, true, "Completion trigger should exist")
end

T["builtin clue generators"]["window commands clues are included"] = function()
    vim.wait(1000)

    local MiniClue = require("mini.clue")
    local config = MiniClue.config

    -- Check that window clues generator is included
    local has_window_clues = false
    for _, clue in ipairs(config.clues) do
        if type(clue) == "function" then
            -- Window clues are generated by a function
            has_window_clues = true
            break
        end
    end

    MiniTest.expect.equality(has_window_clues, true, "Window clues generator should be included")
end

T["builtin clue generators"]["marks clues are included"] = function()
    vim.wait(1000)

    local MiniClue = require("mini.clue")
    local config = MiniClue.config

    -- Check for marks triggers
    local has_marks_trigger = false
    for _, trigger in ipairs(config.triggers) do
        if (trigger.keys == "'" or trigger.keys == "`") and trigger.mode == "n" then
            has_marks_trigger = true
            break
        end
    end

    MiniTest.expect.equality(has_marks_trigger, true, "Marks trigger should exist")
end

T["builtin clue generators"]["registers clues are included"] = function()
    vim.wait(1000)

    local MiniClue = require("mini.clue")
    local config = MiniClue.config

    -- Check for registers trigger
    local has_registers_trigger = false
    for _, trigger in ipairs(config.triggers) do
        if trigger.keys == '"' and trigger.mode == "n" then
            has_registers_trigger = true
            break
        end
    end

    MiniTest.expect.equality(has_registers_trigger, true, "Registers trigger should exist")
end

-- For manual running
if ... == nil then MiniTest.run() end

return T
