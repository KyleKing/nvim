-- Test mini.clue integration
-- Includes automatic detection of new gen_clues generators
-- When mini.clue adds new generators, the test "all available gen_clues are used or intentionally skipped"
-- will fail and prompt you to either:
--   1. Add the generator to your config (lua/kyleking/deps/keybinding.lua)
--   2. Add it to the expected_config skip list with a reason
local MiniTest = require("mini.test")
local helpers = require("tests.helpers")

local function resolve_leader(keys) return keys:gsub("<[Ll]eader>", vim.g.mapleader or "\\") end

local T = MiniTest.new_set({
    hooks = {
        pre_case = function()
            -- Clean up before each test
        end,
    },
})

T["mini.clue"] = MiniTest.new_set()

T["mini.clue"]["mini.clue is configured"] = function()
    -- Wait for later() to execute
    helpers.wait_for_plugins()
    MiniTest.expect.equality(helpers.is_plugin_loaded("mini.clue"), true, "mini.clue should be loaded")
end

T["clue configuration"] = MiniTest.new_set()

T["clue configuration"]["leader triggers are configured"] = function()
    helpers.wait_for_plugins()

    local MiniClue = require("mini.clue")
    local config = MiniClue.config

    -- Check that triggers include leader with mode array
    local has_leader_trigger = false
    for _, trigger in ipairs(config.triggers) do
        if trigger.keys == "<Leader>" then
            -- Accept either mode array or single mode
            local modes = type(trigger.mode) == "table" and trigger.mode or { trigger.mode }
            for _, mode in ipairs(modes) do
                if mode == "n" then
                    has_leader_trigger = true
                    break
                end
            end
        end
    end

    MiniTest.expect.equality(has_leader_trigger, true, "Leader trigger should be configured")
end

T["clue configuration"]["built-in triggers are configured"] = function()
    helpers.wait_for_plugins()

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
    helpers.wait_for_plugins()

    local MiniClue = require("mini.clue")
    local config = MiniClue.config

    MiniTest.expect.equality(type(config.window.delay), "number", "Window delay should be a number")
    MiniTest.expect.equality(config.window.delay, 500, "Window delay should be 500ms")
end

T["clue configuration"]["window has rounded border"] = function()
    helpers.wait_for_plugins()

    local MiniClue = require("mini.clue")
    local config = MiniClue.config

    MiniTest.expect.equality(config.window.config.border, "rounded", "Window should have rounded border")
end

T["clue configuration"]["uses mode arrays for common triggers"] = function()
    helpers.wait_for_plugins()

    local MiniClue = require("mini.clue")
    local config = MiniClue.config

    -- Check that common triggers use mode arrays instead of separate entries
    local trigger_counts = {}
    for _, trigger in ipairs(config.triggers) do
        local key = trigger.keys
        trigger_counts[key] = (trigger_counts[key] or 0) + 1
    end

    -- Common triggers should appear only once (using mode arrays)
    local common_triggers = { "<Leader>", "g", "'", "`", '"', "z" }
    for _, key in ipairs(common_triggers) do
        MiniTest.expect.equality(
            trigger_counts[key],
            1,
            string.format("Trigger '%s' should use mode array (found %d entries)", key, trigger_counts[key] or 0)
        )
    end
end

T["group descriptions"] = MiniTest.new_set()

T["group descriptions"]["leader groups are defined"] = function()
    helpers.wait_for_plugins()

    local MiniClue = require("mini.clue")
    local config = MiniClue.config

    -- Check that clues include group descriptions
    local groups = {}
    for _, clue in ipairs(config.clues) do
        if type(clue) == "table" and clue.desc and clue.desc:match("^%+") then groups[clue.keys] = clue.desc end
    end

    -- Expected groups
    local expected_groups = {
        ["<Leader>?"] = "+Help",
        ["<Leader>b"] = "+Buffer",
        ["<Leader>c"] = "+Code",
        ["<Leader>f"] = "+Find",
        ["<Leader>g"] = "+Git",
        ["<Leader>k"] = "+Keys",
        ["<Leader>l"] = "+LSP",
        ["<Leader>m"] = "+Move",
        ["<Leader>p"] = "+Plugins",
        ["<Leader>r"] = "+Register",
        ["<Leader>t"] = "+Terminal/Test",
        ["<Leader>u"] = "+UI",
        ["<Leader>w"] = "+Window",
    }

    for keys, expected_desc in pairs(expected_groups) do
        MiniTest.expect.equality(groups[keys], expected_desc, "Group should exist: " .. keys)
    end
end

T["group descriptions"]["LSP subgroups are defined"] = function()
    helpers.wait_for_plugins()

    local MiniClue = require("mini.clue")
    local config = MiniClue.config

    local groups = {}
    for _, clue in ipairs(config.clues) do
        if type(clue) == "table" and clue.desc and clue.desc:match("^%+") then groups[clue.keys] = clue.desc end
    end

    MiniTest.expect.equality(groups["<Leader>lg"], "+LSP Go to", "LSP Go to group should exist")
    MiniTest.expect.equality(groups["<Leader>ls"], "+Semantic", "Semantic group should exist")
end

T["group descriptions"]["UI subgroups are defined"] = function()
    helpers.wait_for_plugins()

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
    helpers.wait_for_plugins()

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
    helpers.wait_for_plugins()

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
    helpers.wait_for_plugins()

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
    helpers.wait_for_plugins()

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

T["builtin clue generators"]["square_brackets clues are included"] = function()
    helpers.wait_for_plugins()

    local MiniClue = require("mini.clue")
    local config = MiniClue.config

    -- Check for bracket triggers
    local has_bracket_trigger = false
    for _, trigger in ipairs(config.triggers) do
        if (trigger.keys == "[" or trigger.keys == "]") and trigger.mode == "n" then
            has_bracket_trigger = true
            break
        end
    end

    MiniTest.expect.equality(has_bracket_trigger, true, "Bracket trigger should exist")
end

T["builtin clue generators"]["all available gen_clues are used or intentionally skipped"] = function()
    helpers.wait_for_plugins()

    local MiniClue = require("mini.clue")

    -- Get all available gen_clues functions
    local available_generators = {}
    for name, value in pairs(MiniClue.gen_clues) do
        if type(value) == "function" then table.insert(available_generators, name) end
    end
    table.sort(available_generators)

    -- Expected configuration: generators we use or intentionally skip
    local expected_config = {
        builtin_completion = "used",
        g = "used",
        marks = "used",
        registers = "used",
        square_brackets = "used",
        windows = "used",
        z = "used",
        -- Add skipped generators here with reason:
        -- example_gen = "skipped - not useful for our workflow",
    }

    -- Find generators that exist but aren't in our expected config
    local unknown_generators = {}
    for _, gen_name in ipairs(available_generators) do
        if not expected_config[gen_name] then table.insert(unknown_generators, gen_name) end
    end

    -- Find generators in expected config that no longer exist
    local missing_generators = {}
    for gen_name, status in pairs(expected_config) do
        local exists = false
        for _, available_name in ipairs(available_generators) do
            if available_name == gen_name then
                exists = true
                break
            end
        end
        if not exists then table.insert(missing_generators, gen_name .. " (" .. status .. ")") end
    end

    -- Report findings
    local errors = {}
    if #unknown_generators > 0 then
        table.insert(
            errors,
            "New gen_clues detected - add to expected_config: " .. table.concat(unknown_generators, ", ")
        )
    end
    if #missing_generators > 0 then
        table.insert(errors, "Configured gen_clues no longer exist: " .. table.concat(missing_generators, ", "))
    end

    MiniTest.expect.equality(#errors, 0, table.concat(errors, "; "))
end

T["clue completeness"] = MiniTest.new_set()

T["clue completeness"]["no groups use default +# descriptions"] = function()
    helpers.wait_for_plugins()

    local MiniClue = require("mini.clue")
    local config = MiniClue.config

    -- Collect all group descriptions
    local invalid_descriptions = {}
    for _, clue in ipairs(config.clues) do
        if type(clue) == "table" and clue.desc then
            -- Check if description matches default pattern "+#" or "+1", "+2", etc
            if clue.desc:match("^%+%d+$") then table.insert(invalid_descriptions, clue.keys .. " -> " .. clue.desc) end
        end
    end

    MiniTest.expect.equality(
        #invalid_descriptions,
        0,
        "All groups should have custom descriptions, found default descriptions: "
            .. table.concat(invalid_descriptions, ", ")
    )
end

T["clue completeness"]["all leader group prefixes have descriptions"] = function()
    helpers.wait_for_plugins()

    local leader = vim.g.mapleader or "\\"
    local keymaps = vim.api.nvim_get_keymap("n")
    local leader_prefixes = {}

    for _, keymap in ipairs(keymaps) do
        local lhs = keymap.lhs
        if lhs:sub(1, #leader) == leader then
            local suffix = lhs:sub(#leader + 1)
            for len = 1, math.min(2, #suffix) do
                local prefix = "<Leader>" .. suffix:sub(1, len)
                leader_prefixes[prefix] = true
            end
        end
    end

    local MiniClue = require("mini.clue")
    local config = MiniClue.config

    local clue_groups = {}
    for _, clue in ipairs(config.clues) do
        if type(clue) == "table" and clue.desc and clue.desc:match("^%+") then clue_groups[clue.keys] = true end
    end

    local missing_clues = {}
    for prefix, _ in pairs(leader_prefixes) do
        if not clue_groups[prefix] then table.insert(missing_clues, prefix) end
    end

    table.sort(missing_clues)

    MiniTest.expect.equality(
        #missing_clues,
        0,
        "All leader prefixes should have clue descriptions. Missing: " .. table.concat(missing_clues, ", ")
    )
end

T["clue completeness"]["no orphan clue groups"] = function()
    helpers.wait_for_plugins()

    local MiniClue = require("mini.clue")
    local config = MiniClue.config

    local groups = {}
    for _, clue in ipairs(config.clues) do
        if type(clue) == "table" and clue.desc and clue.desc:match("^%+") then
            table.insert(groups, { keys = clue.keys, mode = clue.mode or "n" })
        end
    end

    local orphans = {}
    for _, group in ipairs(groups) do
        local resolved_prefix = resolve_leader(group.keys)
        local keymaps = vim.api.nvim_get_keymap(group.mode)
        local has_child = false
        for _, keymap in ipairs(keymaps) do
            if keymap.lhs:sub(1, #resolved_prefix) == resolved_prefix and #keymap.lhs > #resolved_prefix then
                has_child = true
                break
            end
        end
        if not has_child then table.insert(orphans, group.keys .. " (" .. group.mode .. ")") end
    end

    table.sort(orphans)

    MiniTest.expect.equality(#orphans, 0, "Clue groups without any keymaps underneath: " .. table.concat(orphans, ", "))
end

T["group descriptions"]["no duplicate descriptions among siblings"] = function()
    helpers.wait_for_plugins()

    local MiniClue = require("mini.clue")
    local config = MiniClue.config

    local siblings = {}
    for _, clue in ipairs(config.clues) do
        if type(clue) == "table" and clue.desc and clue.desc:match("^%+") then
            local parent = clue.keys:match("^(.+).$") or ""
            local mode = clue.mode or "n"
            local key = parent .. "|" .. mode
            siblings[key] = siblings[key] or {}
            table.insert(siblings[key], { keys = clue.keys, desc = clue.desc })
        end
    end

    local duplicates = {}
    for _, group in pairs(siblings) do
        local seen = {}
        for _, entry in ipairs(group) do
            if seen[entry.desc] then
                table.insert(duplicates, entry.keys .. " duplicates " .. seen[entry.desc] .. " (" .. entry.desc .. ")")
            else
                seen[entry.desc] = entry.keys
            end
        end
    end

    table.sort(duplicates)

    MiniTest.expect.equality(
        #duplicates,
        0,
        "Duplicate descriptions among sibling groups: " .. table.concat(duplicates, ", ")
    )
end

T["group descriptions"]["descriptions follow +Name pattern"] = function()
    helpers.wait_for_plugins()

    local MiniClue = require("mini.clue")
    local config = MiniClue.config

    local malformed = {}
    for _, clue in ipairs(config.clues) do
        if type(clue) == "table" and clue.desc and clue.desc:match("^%+") then
            if not clue.desc:match("^%+%u") then table.insert(malformed, clue.keys .. " -> " .. clue.desc) end
        end
    end

    table.sort(malformed)

    MiniTest.expect.equality(
        #malformed,
        0,
        "Group descriptions should match +Name (uppercase after +): " .. table.concat(malformed, ", ")
    )
end

-- For manual running
if ... == nil then MiniTest.run() end

return T
