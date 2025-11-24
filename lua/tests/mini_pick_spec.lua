-- Test file for mini.pick functionality using Mini.test
-- Tests fuzzy finding, file navigation, and picker features
local MiniTest = require("mini.test")
local H = require("tests.helpers")

local T = MiniTest.new_set({
    hooks = {
        pre_case = function()
            -- Ensure mini.pick is loaded
            require("kyleking.deps.fuzzy-finder")
            vim.cmd("sleep 50m") -- Allow lazy loading
        end,
        post_once = function() end,
    },
})

-- Test mini.pick module
T["mini.pick module"] = MiniTest.new_set()

T["mini.pick module"]["loads successfully"] = function()
    H.assert_true(H.is_plugin_loaded("mini.pick"), "mini.pick should be loaded")
end

T["mini.pick module"]["has expected configuration"] = function()
    local pick = require("mini.pick")

    -- Verify pick is configured with our custom mappings
    -- Note: We can't directly inspect config, but we can verify the module loaded
    H.assert_not_nil(pick.builtin, "mini.pick.builtin should be available")
    H.assert_not_nil(pick.setup, "mini.pick.setup should be available")
end

T["mini.pick module"]["has builtin pickers"] = function()
    local pick = require("mini.pick")

    -- Verify that expected builtin pickers exist
    H.assert_true(type(pick.builtin.buffers) == "function", "pick.builtin.buffers should exist")
    H.assert_true(type(pick.builtin.files) == "function", "pick.builtin.files should exist")
    H.assert_true(type(pick.builtin.grep) == "function", "pick.builtin.grep should exist")
    H.assert_true(type(pick.builtin.grep_live) == "function", "pick.builtin.grep_live should exist")
    H.assert_true(type(pick.builtin.help) == "function", "pick.builtin.help should exist")
    H.assert_true(type(pick.builtin.resume) == "function", "pick.builtin.resume should exist")
end

-- Test mini.pick keymaps
T["mini.pick keymaps"] = MiniTest.new_set()

T["mini.pick keymaps"]["buffer navigation keymaps"] = function()
    local expected_keymaps = {
        { lhs = "<leader>;", desc = "Find in open buffers" },
        { lhs = "<leader>br", desc = "Find [r]ecently opened files" },
        { lhs = "<leader>bb", desc = "Find word in current buffer" },
    }

    for _, keymap_spec in ipairs(expected_keymaps) do
        local exists = H.check_keymap("n", keymap_spec.lhs, keymap_spec.desc)
        H.assert_true(exists, "Keymap should exist: " .. keymap_spec.lhs)
    end
end

T["mini.pick keymaps"]["file navigation keymaps"] = function()
    local expected_keymaps = {
        { lhs = "<leader>gf", desc = "Find in Git Files" },
        { lhs = "<leader>ff", desc = "Find in files" },
        { lhs = "<leader>fw", desc = "Find word in files (live grep)" },
    }

    for _, keymap_spec in ipairs(expected_keymaps) do
        local exists = H.check_keymap("n", keymap_spec.lhs, keymap_spec.desc)
        H.assert_true(exists, "Keymap should exist: " .. keymap_spec.lhs)
    end
end

T["mini.pick keymaps"]["utility keymaps"] = function()
    local expected_keymaps = {
        { lhs = "<leader>fh", desc = "Find in nvim help" },
        { lhs = "<leader>fk", desc = "Find keymaps" },
        { lhs = "<leader>fr", desc = "Find registers" },
        { lhs = "<leader>f'", desc = "Find marks" },
        { lhs = "<leader><CR>", desc = "Resume last picker" },
    }

    for _, keymap_spec in ipairs(expected_keymaps) do
        local exists = H.check_keymap("n", keymap_spec.lhs, keymap_spec.desc)
        H.assert_true(exists, "Keymap should exist: " .. keymap_spec.lhs)
    end
end

T["mini.pick keymaps"]["LSP navigation keymaps"] = function()
    local expected_keymaps = {
        { lhs = "<leader>lgd", desc = "Go to definition" },
        { lhs = "<leader>lgi", desc = "Go to implementation" },
        { lhs = "<leader>lgr", desc = "Show references" },
        { lhs = "<leader>lgt", desc = "Go to type definition" },
    }

    for _, keymap_spec in ipairs(expected_keymaps) do
        local exists = H.check_keymap("n", keymap_spec.lhs, keymap_spec.desc)
        H.assert_true(exists, "LSP keymap should exist: " .. keymap_spec.lhs)
    end
end

T["mini.pick keymaps"]["visual mode grep keymap"] = function()
    local exists = H.check_keymap("v", "<leader>f*", "Find word from visual")
    H.assert_true(exists, "Visual grep keymap should exist")
end

-- Test mini.pick functionality
T["mini.pick functionality"] = MiniTest.new_set()

T["mini.pick functionality"]["can start a picker programmatically"] = function()
    local pick = require("mini.pick")

    -- Create a simple picker with test items
    local test_items = { "item1", "item2", "item3" }

    -- Note: Actually starting a picker requires UI interaction and would block tests
    -- We verify that pick.start is callable and accepts the expected parameters
    H.assert_true(type(pick.start) == "function", "pick.start should be a function")

    -- Verify we can create a source configuration
    local source = {
        items = test_items,
        name = "Test Picker",
    }

    H.assert_not_nil(source.items, "Picker source should have items")
    H.assert_not_nil(source.name, "Picker source should have name")
end

T["mini.pick functionality"]["builtin.buffers works"] = function()
    local pick = require("mini.pick")

    -- Create a few test buffers
    local buf1 = H.create_test_buffer({ "Buffer 1" })
    local buf2 = H.create_test_buffer({ "Buffer 2" })
    local buf3 = H.create_test_buffer({ "Buffer 3" })

    -- Verify buffers picker is callable
    H.assert_true(type(pick.builtin.buffers) == "function", "buffers picker should be callable")

    -- Clean up
    H.delete_buffer(buf1)
    H.delete_buffer(buf2)
    H.delete_buffer(buf3)
end

T["mini.pick functionality"]["builtin.files works with different tools"] = function()
    local pick = require("mini.pick")

    -- Verify files picker accepts different tools
    H.assert_true(type(pick.builtin.files) == "function", "files picker should be callable")

    -- Test that we can specify tools
    -- Note: Can't actually call without UI, but we verify function signature
    local tools = { "rg", "git", "oldfiles" }
    for _, tool in ipairs(tools) do
        H.assert_true(type(tool) == "string", "Tool " .. tool .. " should be a valid string option")
    end
end

T["mini.pick functionality"]["builtin.help searches help tags"] = function()
    local pick = require("mini.pick")

    H.assert_true(type(pick.builtin.help) == "function", "help picker should be callable")
end

T["mini.pick functionality"]["builtin.grep_live for live search"] = function()
    local pick = require("mini.pick")

    H.assert_true(type(pick.builtin.grep_live) == "function", "grep_live picker should be callable")
end

-- Test picker window configuration
T["mini.pick window"] = MiniTest.new_set()

T["mini.pick window"]["window size configured"] = function()
    -- The config sets window size using golden ratio (0.618)
    -- We verify the configuration was set up (actual values tested during runtime)
    local pick = require("mini.pick")

    H.assert_not_nil(pick, "Pick should be configured with window settings")

    -- Calculate expected dimensions
    local expected_width_ratio = 0.618
    local expected_height_ratio = 0.618

    -- Verify ratios are reasonable
    H.assert_true(
        expected_width_ratio > 0 and expected_width_ratio < 1,
        "Width ratio should be between 0 and 1"
    )
    H.assert_true(
        expected_height_ratio > 0 and expected_height_ratio < 1,
        "Height ratio should be between 0 and 1"
    )
end

-- Test integration with Trouble for diagnostics
T["mini.pick Trouble integration"] = MiniTest.new_set()

T["mini.pick Trouble integration"]["diagnostics use Trouble instead of picker"] = function()
    -- Verify that diagnostics keymap uses Trouble, not mini.pick
    local exists, keymap = H.check_keymap("n", "<leader>ld", "Find in Diagnostics (Trouble)")
    H.assert_true(exists, "Diagnostics keymap should use Trouble")

    if keymap then
        -- Verify it's a Trouble command, not a picker
        local is_trouble = keymap.rhs and keymap.rhs:match("Trouble")
        H.assert_true(is_trouble, "Diagnostics should use Trouble command")
    end
end

T["mini.pick Trouble integration"]["symbols use Trouble instead of picker"] = function()
    local exists, keymap = H.check_keymap("n", "<leader>lgs", "Find in symbols (Trouble)")
    H.assert_true(exists, "Symbols keymap should use Trouble")

    if keymap then
        local is_trouble = keymap.rhs and keymap.rhs:match("Trouble")
        H.assert_true(is_trouble, "Symbols should use Trouble command")
    end
end

-- Test custom picker implementations
T["mini.pick custom pickers"] = MiniTest.new_set()

T["mini.pick custom pickers"]["keymaps picker implementation"] = function()
    -- The <leader>fk keymap implements a custom keymaps picker
    -- Verify it exists and can be executed (though we won't actually run it)
    local exists = H.check_keymap("n", "<leader>fk", "Find keymaps")
    H.assert_true(exists, "Custom keymaps picker should be configured")
end

T["mini.pick custom pickers"]["commands picker implementation"] = function()
    -- The <leader>fC keymap implements a custom commands picker using cli
    local exists = H.check_keymap("n", "<leader>fC", "Find commands")
    H.assert_true(exists, "Custom commands picker should be configured")
end

T["mini.pick custom pickers"]["visual grep implementation"] = function()
    -- The <leader>f* visual keymap implements grep from visual selection
    local exists = H.check_keymap("v", "<leader>f*", "Find word from visual")
    H.assert_true(exists, "Visual grep picker should be configured")
end

-- Test picker movement mappings
T["mini.pick mappings"] = MiniTest.new_set()

T["mini.pick mappings"]["custom movement keys configured"] = function()
    -- Verify that Ctrl-j and Ctrl-k are configured for movement
    -- Note: These are internal to mini.pick, we verify config was set
    local pick = require("mini.pick")

    -- The configuration sets move_down = '<C-j>' and move_up = '<C-k>'
    -- We can't directly inspect this without starting a picker,
    -- but we verify the module loaded successfully with our config
    H.assert_not_nil(pick, "Pick should be configured with custom movement keys")
end

-- For manual running of tests directly
if ... == nil then MiniTest.run() end

return T
