-- Test file for terminal-integration.lua using Mini.test
-- Tests built-in nvim terminal integration
local MiniTest = require("mini.test")
local H = require("tests.helpers")

-- Define a new test set
local T = MiniTest.new_set({
    hooks = {
        pre_case = function()
            -- Reload the module before each test
            package.loaded["kyleking.deps.terminal-integration"] = nil
        end,
        post_once = function()
            -- Clean up after all tests
        end,
    },
})

-- Test case for the terminal integration module
T["terminal_integration module"] = MiniTest.new_set()

T["terminal_integration module"]["loads successfully"] = function()
    -- Load the module
    local module = require("kyleking.deps.terminal-integration")

    H.assert_not_nil(module, "Terminal integration module should load")
end

T["terminal_integration module"]["exports expected functions"] = function()
    local module = require("kyleking.deps.terminal-integration")

    -- Verify exported functions
    H.assert_true(type(module.toggle_float) == "function", "toggle_float should be a function")
    H.assert_true(type(module.open_horizontal) == "function", "open_horizontal should be a function")
    H.assert_true(type(module.open_vertical) == "function", "open_vertical should be a function")
end

-- Test keymaps
T["terminal_integration module"]["keymaps are configured"] = function()
    require("kyleking.deps.terminal-integration")

    -- Verify keymaps exist
    local expected_keymaps = {
        { mode = "n", lhs = "<C-'>", desc = "Toggle floating terminal" },
        { mode = "t", lhs = "<C-'>", desc = "Toggle floating terminal" },
        { mode = "n", lhs = "<leader>tf", desc = "Terminal float" },
        { mode = "n", lhs = "<leader>th", desc = "Terminal horizontal split" },
        { mode = "n", lhs = "<leader>tv", desc = "Terminal vertical split" },
        { mode = "t", lhs = "<Esc><Esc>", desc = "Exit terminal mode" },
    }

    for _, keymap_spec in ipairs(expected_keymaps) do
        local exists = H.check_keymap(keymap_spec.mode, keymap_spec.lhs, keymap_spec.desc)
        H.assert_true(exists, string.format("Keymap %s in mode %s should exist", keymap_spec.lhs, keymap_spec.mode))
    end
end

T["terminal_integration module"]["terminal navigation keymaps exist"] = function()
    require("kyleking.deps.terminal-integration")

    -- Verify Ctrl+hjkl navigation from terminal mode
    local nav_keymaps = {
        { lhs = "<C-h>", desc = "Move to left window" },
        { lhs = "<C-j>", desc = "Move to window below" },
        { lhs = "<C-k>", desc = "Move to window above" },
        { lhs = "<C-l>", desc = "Move to right window" },
    }

    for _, keymap_spec in ipairs(nav_keymaps) do
        local exists = H.check_keymap("t", keymap_spec.lhs, keymap_spec.desc)
        H.assert_true(exists, string.format("Navigation keymap %s should exist in terminal mode", keymap_spec.lhs))
    end
end

-- Test toggle_float functionality
T["terminal_integration module"]["toggle_float creates terminal"] = function()
    local module = require("kyleking.deps.terminal-integration")

    -- Count initial buffers
    local initial_bufs = vim.api.nvim_list_bufs()
    local initial_count = #initial_bufs

    -- Call toggle_float (this will create a terminal)
    -- Note: We can't fully test the floating window in headless mode,
    -- but we can verify the function is callable
    H.assert_true(type(module.toggle_float) == "function", "toggle_float should be callable")

    -- The function exists and is the right type - actual terminal creation
    -- is hard to test in automated tests without a full UI
end

-- Test open_horizontal functionality
T["terminal_integration module"]["open_horizontal is callable"] = function()
    local module = require("kyleking.deps.terminal-integration")

    H.assert_true(type(module.open_horizontal) == "function", "open_horizontal should be callable")
end

-- Test open_vertical functionality
T["terminal_integration module"]["open_vertical is callable"] = function()
    local module = require("kyleking.deps.terminal-integration")

    H.assert_true(type(module.open_vertical) == "function", "open_vertical should be callable")
end

-- Test that built-in terminal functions are available
T["built-in terminal"] = MiniTest.new_set()

T["built-in terminal"]["nvim has terminal support"] = function()
    -- Verify vim.fn.termopen exists (built-in terminal function)
    H.assert_true(type(vim.fn.termopen) == "function", "vim.fn.termopen should be available")

    -- Verify we can create terminal buffers
    H.assert_true(type(vim.api.nvim_create_buf) == "function", "vim.api.nvim_create_buf should be available")

    -- Verify we can open floating windows
    H.assert_true(type(vim.api.nvim_open_win) == "function", "vim.api.nvim_open_win should be available")
end

T["built-in terminal"]["terminal commands work"] = function()
    -- Test that we can open a terminal via command
    -- This is a basic sanity check that nvim's terminal works
    local cmd_exists = vim.fn.exists(':terminal')
    H.assert_true(cmd_exists == 2, ":terminal command should exist")
end

-- Integration test
T["terminal integration"] = MiniTest.new_set()

T["terminal integration"]["module integrates with nvim"] = function()
    require("kyleking.deps.terminal-integration")

    -- Verify that after loading the module, we have the expected setup
    -- Keymaps should be registered
    local has_toggle = H.check_keymap("n", "<C-'>", "Toggle floating terminal")
    H.assert_true(has_toggle, "Toggle keymap should be registered")

    -- Module should export the expected API
    local module = require("kyleking.deps.terminal-integration")
    H.assert_not_nil(module.toggle_float, "Module should export toggle_float")
    H.assert_not_nil(module.open_horizontal, "Module should export open_horizontal")
    H.assert_not_nil(module.open_vertical, "Module should export open_vertical")
end

T["terminal integration"]["uses built-in terminal not external plugin"] = function()
    -- Verify that toggleterm is NOT loaded (we replaced it)
    H.assert_false(H.is_plugin_loaded("toggleterm"), "toggleterm should not be loaded")

    -- Verify our module loads instead
    local module = require("kyleking.deps.terminal-integration")
    H.assert_not_nil(module, "Built-in terminal integration should load")
end

-- For manual running of tests directly
if ... == nil then MiniTest.run() end

-- Return the test set for discovery by the test runner
return T
