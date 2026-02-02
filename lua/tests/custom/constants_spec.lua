-- Test for constants module
local MiniTest = require("mini.test")

local T = MiniTest.new_set({ hooks = {} })

T["constants module"] = MiniTest.new_set()

T["constants module"]["can be required"] = function()
    local ok, constants = pcall(require, "kyleking.utils.constants")
    MiniTest.expect.equality(ok, true, "constants module should be loadable")
    MiniTest.expect.equality(type(constants), "table", "constants should be a table")
end

T["constants module"]["has IGNORED_PATHS"] = function()
    local constants = require("kyleking.utils.constants")
    MiniTest.expect.equality(type(constants.IGNORED_PATHS), "table", "IGNORED_PATHS should be a table")
    MiniTest.expect.equality(#constants.IGNORED_PATHS > 0, true, "IGNORED_PATHS should not be empty")
end

T["constants module"]["IGNORED_PATHS contains expected entries"] = function()
    local constants = require("kyleking.utils.constants")
    local ignored = constants.IGNORED_PATHS

    -- Check for common ignore patterns
    local has_ds_store = false
    local has_git = false
    local has_pycache = false
    local has_node_modules = false

    for _, path in ipairs(ignored) do
        if path == ".DS_Store" then has_ds_store = true end
        if path == ".git" then has_git = true end
        if path == "__pycache__" then has_pycache = true end
        if path == "node_modules" then has_node_modules = true end
    end

    MiniTest.expect.equality(has_ds_store, true, "Should ignore .DS_Store")
    MiniTest.expect.equality(has_git, true, "Should ignore .git")
    MiniTest.expect.equality(has_pycache, true, "Should ignore __pycache__")
    MiniTest.expect.equality(has_node_modules, true, "Should ignore node_modules")
end

T["constants module"]["should_ignore function"] = MiniTest.new_set()

T["constants module"]["should_ignore function"]["exists and is callable"] = function()
    local constants = require("kyleking.utils.constants")
    MiniTest.expect.equality(type(constants.should_ignore), "function", "should_ignore should be a function")
end

T["constants module"]["should_ignore function"]["returns true for ignored paths"] = function()
    local constants = require("kyleking.utils.constants")

    MiniTest.expect.equality(constants.should_ignore(".DS_Store"), true, "Should ignore .DS_Store")
    MiniTest.expect.equality(constants.should_ignore(".git"), true, "Should ignore .git")
    MiniTest.expect.equality(constants.should_ignore("__pycache__"), true, "Should ignore __pycache__")
    MiniTest.expect.equality(constants.should_ignore("node_modules"), true, "Should ignore node_modules")
end

T["constants module"]["should_ignore function"]["returns false for non-ignored paths"] = function()
    local constants = require("kyleking.utils.constants")

    MiniTest.expect.equality(constants.should_ignore("README.md"), false, "Should not ignore README.md")
    MiniTest.expect.equality(constants.should_ignore("src"), false, "Should not ignore src")
    MiniTest.expect.equality(constants.should_ignore("main.lua"), false, "Should not ignore main.lua")
end

T["constants module"]["other constants"] = MiniTest.new_set()

T["constants module"]["other constants"]["has DELAY table"] = function()
    local constants = require("kyleking.utils.constants")
    MiniTest.expect.equality(type(constants.DELAY), "table", "DELAY should be a table")
    MiniTest.expect.equality(type(constants.DELAY.PLUGIN_LOAD), "number", "PLUGIN_LOAD should be a number")
end

T["constants module"]["other constants"]["has WINDOW table"] = function()
    local constants = require("kyleking.utils.constants")
    MiniTest.expect.equality(type(constants.WINDOW), "table", "WINDOW should be a table")
    MiniTest.expect.equality(type(constants.WINDOW.STANDARD), "number", "STANDARD should be a number")
end

T["constants module"]["other constants"]["has CHAR_LIMIT table"] = function()
    local constants = require("kyleking.utils.constants")
    MiniTest.expect.equality(type(constants.CHAR_LIMIT), "table", "CHAR_LIMIT should be a table")
    MiniTest.expect.equality(type(constants.CHAR_LIMIT.FILENAME_MIN), "number", "FILENAME_MIN should be a number")
end

-- Run tests if executed directly
if MiniTest.current.all_cases == nil then MiniTest.run() end

return T
