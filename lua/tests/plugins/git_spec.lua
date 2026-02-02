-- Test git plugins (mini.diff, mini.git, diffview)
local MiniTest = require("mini.test")
local helpers = require("tests.helpers")

local T = MiniTest.new_set({
    hooks = {
        pre_case = function()
            -- Clean up before each test
        end,
    },
})

T["git plugins"] = MiniTest.new_set()

T["git plugins"]["git module loads without errors"] = function()
    MiniTest.expect.no_error(function() require("kyleking.deps.git") end)
end

T["mini.diff"] = MiniTest.new_set()

T["mini.diff"]["mini.diff is configured"] = function()
    vim.wait(1000)
    MiniTest.expect.equality(helpers.is_plugin_loaded("mini.diff"), true, "mini.diff should be loaded")
end

T["mini.diff"]["toggle overlay keymap is set"] = function()
    vim.wait(1000)

    local keymap = vim.fn.maparg("<leader>ugd", "n", false, true)
    MiniTest.expect.equality(keymap ~= nil and keymap.lhs ~= nil, true, "<leader>ugd mapping should exist")

    local has_callable = (type(keymap.callback) == "function") or (type(keymap.rhs) == "string" and keymap.rhs ~= "")
    MiniTest.expect.equality(has_callable, true, "<leader>ugd should have callable rhs (prevents nil errors)")
end

T["mini.diff"]["toggle_overlay is callable"] = function()
    vim.wait(1000)

    local diff = require("mini.diff")
    MiniTest.expect.equality(type(diff.toggle_overlay), "function", "toggle_overlay should be a function")
end

T["mini.git"] = MiniTest.new_set()

T["mini.git"]["mini.git is configured"] = function()
    vim.wait(1000)
    MiniTest.expect.equality(helpers.is_plugin_loaded("mini.git"), true, "mini.git should be loaded")
end

T["diffview"] = MiniTest.new_set()

T["diffview"]["diffview is configured"] = function()
    vim.wait(1000)
    MiniTest.expect.equality(helpers.is_plugin_loaded("diffview"), true, "diffview should be loaded")
end

T["diffview"]["diffview functions are callable"] = function()
    vim.wait(1000)

    -- Diffview loads on demand, so just check that the module can be required
    MiniTest.expect.no_error(function()
        local diffview = require("diffview")
        MiniTest.expect.equality(type(diffview), "table", "diffview should be a table")
    end)
end

-- For manual running
if ... == nil then MiniTest.run() end

return T
