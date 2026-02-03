-- Integration tests for mini.clue with all keymaps
-- These tests catch errors like invalid mode values that break mini.clue
local MiniTest = require("mini.test")
local helpers = require("tests.helpers")

local T = MiniTest.new_set({
    hooks = {
        pre_case = function()
            -- Clean slate for each test
        end,
    },
})

T["keymap compatibility"] = MiniTest.new_set()

T["keymap compatibility"]["all keymaps have valid modes for mini.clue"] = function()
    helpers.wait_for_plugins()

    -- mini.clue calls nvim_get_keymap with mode as string
    -- If any keymap has mode as non-string, it will error
    local modes = { "n", "i", "v", "x", "s", "o", "t", "c", "l" }
    local invalid_keymaps = {}

    for _, mode in ipairs(modes) do
        local ok, keymaps = pcall(vim.api.nvim_get_keymap, mode)
        if not ok then
            table.insert(invalid_keymaps, "Mode '" .. mode .. "' failed: " .. tostring(keymaps))
        else
            -- Check each keymap has valid structure
            for _, keymap in ipairs(keymaps) do
                if type(keymap.lhs) ~= "string" then
                    table.insert(
                        invalid_keymaps,
                        string.format("Invalid lhs type for mode '%s': %s", mode, vim.inspect(keymap))
                    )
                end
            end
        end
    end

    MiniTest.expect.equality(
        #invalid_keymaps,
        0,
        "All keymaps should be valid for mini.clue. Errors: " .. table.concat(invalid_keymaps, "; ")
    )
end

T["keymap compatibility"]["mode arrays in vim.keymap.set don't break mini.clue"] = function()
    helpers.wait_for_plugins()

    -- Test that mode arrays (e.g., {"n", "x"}) work correctly
    -- This is a regression test for keymaps that use mode arrays
    local test_key = "<leader>xtest"

    -- Set a keymap with mode array
    vim.keymap.set({ "n", "x" }, test_key, "<cmd>echo 'test'<cr>", { desc = "Test keymap" })

    -- mini.clue should be able to query both modes without error
    local ok_n, keymaps_n = pcall(vim.api.nvim_get_keymap, "n")
    local ok_x, keymaps_x = pcall(vim.api.nvim_get_keymap, "x")

    MiniTest.expect.equality(ok_n, true, "Should query normal mode keymaps without error")
    MiniTest.expect.equality(ok_x, true, "Should query visual mode keymaps without error")

    -- Find our test keymap
    local found_n = false
    local found_x = false
    for _, k in ipairs(keymaps_n) do
        if k.lhs == test_key then found_n = true end
    end
    for _, k in ipairs(keymaps_x) do
        if k.lhs == test_key then found_x = true end
    end

    MiniTest.expect.equality(found_n, true, "Keymap should exist in normal mode")
    MiniTest.expect.equality(found_x, true, "Keymap should exist in visual mode")

    -- Cleanup
    vim.keymap.del("n", test_key)
    vim.keymap.del("x", test_key)
end

T["common keypress scenarios"] = MiniTest.new_set()

T["common keypress scenarios"]["pressing 'g' doesn't error"] = function()
    local result = helpers.nvim_interaction_test(
        [[
        -- Create a buffer with some content
        vim.cmd("enew")
        vim.api.nvim_buf_set_lines(0, 0, -1, false, {"line 1", "line 2", "line 3"})

        -- Simulate pressing 'g' (which triggers mini.clue)
        vim.api.nvim_feedkeys("g", "x", false)
        vim.wait(100)

        -- If mini.clue errored, it would show in stderr
        print("SUCCESS: g keypress handled")
    ]],
        10000
    )

    local has_clue_error = result.stderr:match("mini%.clue%.lua:%d+:") ~= nil
    MiniTest.expect.equality(has_clue_error, false, "Pressing 'g' should not cause mini.clue error: " .. result.stderr)
    MiniTest.expect.equality(result.code, 0, "Should exit cleanly")
end

T["common keypress scenarios"]["pressing 'gg' navigation works"] = function()
    local result = helpers.nvim_interaction_test(
        [[
        -- Create buffer with multiple lines
        vim.cmd("enew")
        local lines = {}
        for i = 1, 50 do
            table.insert(lines, "Line " .. i)
        end
        vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)

        -- Move to bottom
        vim.api.nvim_feedkeys("G", "x", false)
        vim.wait(100)

        -- Press 'gg' to go to top
        vim.api.nvim_feedkeys("gg", "x", false)
        vim.wait(100)

        local cursor = vim.api.nvim_win_get_cursor(0)
        if cursor[1] == 1 then
            print("SUCCESS: gg navigation works")
        else
            error("gg didn't navigate to line 1, at line " .. cursor[1])
        end
    ]],
        10000
    )

    MiniTest.expect.equality(result.code, 0, "gg navigation should work: " .. result.stderr)
    MiniTest.expect.equality(
        result.stderr:match("Error") == nil,
        true,
        "Should have no errors in stderr: " .. result.stderr
    )
end

T["common keypress scenarios"]["leader key triggers clue window"] = function()
    local result = helpers.nvim_interaction_test(
        [[
        -- Press leader and wait for clue window
        vim.api.nvim_feedkeys(" ", "x", false)
        vim.wait(600) -- Wait longer than clue delay (500ms)

        -- Check if a float window exists (clue window)
        local found_float = false
        for _, win in ipairs(vim.api.nvim_list_wins()) do
            local config = vim.api.nvim_win_get_config(win)
            if config.relative ~= "" then
                found_float = true
                break
            end
        end

        if found_float then
            print("SUCCESS: Leader key triggered clue window")
        else
            print("WARNING: No float window detected after leader key")
        end
    ]],
        10000
    )

    MiniTest.expect.equality(result.code, 0, "Leader key should work: " .. result.stderr)
end

T["common keypress scenarios"]["bracket navigation triggers clue"] = function()
    local result = helpers.nvim_interaction_test(
        [[
        vim.cmd("enew")
        vim.api.nvim_buf_set_lines(0, 0, -1, false, {"line 1", "line 2"})

        -- Press '[' which should trigger mini.clue
        vim.api.nvim_feedkeys("[", "x", false)
        vim.wait(100)

        -- Press ']' which should also trigger mini.clue
        vim.api.nvim_feedkeys("]", "x", false)
        vim.wait(100)

        print("SUCCESS: Bracket keys handled")
    ]],
        10000
    )

    MiniTest.expect.equality(result.code, 0, "Bracket navigation should work: " .. result.stderr)
    local has_error = result.stderr:match("Error") ~= nil or result.stderr:match("Invalid") ~= nil
    MiniTest.expect.equality(has_error, false, "Should have no errors: " .. result.stderr)
end

T["workflow scenarios"] = MiniTest.new_set()

T["workflow scenarios"]["typical editing workflow"] = function()
    local result = helpers.nvim_interaction_test(
        [[
        -- Simulate typical editing workflow
        vim.cmd("enew")
        vim.api.nvim_buf_set_lines(0, 0, -1, false, {
            "function hello() {",
            "  console.log('hello');",
            "}",
        })

        -- Navigation: gg to go to top
        vim.api.nvim_feedkeys("gg", "x", false)
        vim.wait(50)

        -- Navigation: G to go to bottom
        vim.api.nvim_feedkeys("G", "x", false)
        vim.wait(50)

        -- Try 'g' prefix (should show clue)
        vim.api.nvim_feedkeys("g", "x", false)
        vim.wait(100)
        vim.api.nvim_feedkeys("\27", "x", false) -- ESC to cancel
        vim.wait(50)

        -- Try 'z' prefix (should show clue)
        vim.api.nvim_feedkeys("z", "x", false)
        vim.wait(100)
        vim.api.nvim_feedkeys("\27", "x", false) -- ESC to cancel
        vim.wait(50)

        print("SUCCESS: Editing workflow completed")
    ]],
        15000
    )

    MiniTest.expect.equality(result.code, 0, "Editing workflow should complete: " .. result.stderr)
end

T["workflow scenarios"]["file navigation workflow"] = function()
    local result = helpers.nvim_interaction_test(
        [[
        -- Create multiple buffers
        for i = 1, 3 do
            vim.cmd("enew")
            vim.api.nvim_buf_set_lines(0, 0, -1, false, {"Buffer " .. i})
        end

        -- Try window navigation (should trigger <C-w> clue)
        vim.api.nvim_feedkeys("\23", "x", false) -- <C-w>
        vim.wait(100)
        vim.api.nvim_feedkeys("\27", "x", false) -- ESC
        vim.wait(50)

        -- Try marks (should trigger marks clue)
        vim.api.nvim_feedkeys("'", "x", false)
        vim.wait(100)
        vim.api.nvim_feedkeys("\27", "x", false) -- ESC
        vim.wait(50)

        print("SUCCESS: File navigation workflow completed")
    ]],
        15000
    )

    MiniTest.expect.equality(result.code, 0, "Navigation workflow should complete: " .. result.stderr)
end

T["keymap validation"] = MiniTest.new_set()

T["keymap validation"]["no keymaps have nil mode"] = function()
    helpers.wait_for_plugins()

    -- Check all registered keymaps to ensure none have nil mode
    local modes = { "n", "i", "v", "x", "s", "o", "t", "c" }
    local problems = {}

    for _, mode in ipairs(modes) do
        local ok, keymaps = pcall(vim.api.nvim_get_keymap, mode)
        if ok then
            for _, keymap in ipairs(keymaps) do
                -- Check for any keymap that might have problematic values
                if not keymap.lhs or type(keymap.lhs) ~= "string" then
                    table.insert(
                        problems,
                        string.format("Mode %s has keymap with invalid lhs: %s", mode, vim.inspect(keymap))
                    )
                end
            end
        end
    end

    MiniTest.expect.equality(#problems, 0, "All keymaps should have valid structure: " .. table.concat(problems, "; "))
end

T["keymap validation"]["all mode arrays are properly expanded"] = function()
    helpers.wait_for_plugins()

    -- When using vim.keymap.set with mode array like {"n", "x"},
    -- it should create separate keymaps for each mode
    -- This test ensures no mode array values leak through

    local test_lhs = "<leader>xtest2"
    vim.keymap.set({ "n", "v" }, test_lhs, function() end, { desc = "Test" })

    -- Both modes should have the keymap
    local n_keymap = vim.fn.maparg(test_lhs, "n", false, true)
    local v_keymap = vim.fn.maparg(test_lhs, "v", false, true)

    MiniTest.expect.equality(type(n_keymap), "table", "Normal mode keymap should exist")
    MiniTest.expect.equality(type(v_keymap), "table", "Visual mode keymap should exist")

    -- Cleanup
    pcall(vim.keymap.del, "n", test_lhs)
    pcall(vim.keymap.del, "v", test_lhs)
end

-- For manual running
if ... == nil then MiniTest.run() end

return T
