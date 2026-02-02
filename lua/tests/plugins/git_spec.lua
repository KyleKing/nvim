-- Test git plugins (gitsigns, diffview)
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

T["gitsigns"] = MiniTest.new_set()

T["gitsigns"]["gitsigns is configured"] = function()
    vim.wait(1000)
    MiniTest.expect.equality(helpers.is_plugin_loaded("gitsigns"), true, "gitsigns should be loaded")
end

T["gitsigns"]["gitsigns toggle deleted keymap is set"] = function()
    vim.wait(1000)

    local keymap = vim.fn.maparg("<leader>ugd", "n", false, true)
    MiniTest.expect.equality(keymap ~= nil and keymap.lhs ~= nil, true, "<leader>ugd mapping should exist")

    -- Verify callable
    local has_callable = (type(keymap.callback) == "function") or (type(keymap.rhs) == "string" and keymap.rhs ~= "")
    MiniTest.expect.equality(has_callable, true, "<leader>ugd should have callable rhs")
end

T["gitsigns"]["gitsigns functions are callable"] = function()
    vim.wait(1000)

    local gitsigns = require("gitsigns")
    MiniTest.expect.equality(type(gitsigns.toggle_deleted), "function", "toggle_deleted should be a function")
    MiniTest.expect.equality(type(gitsigns.setup), "function", "setup should be a function")
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
