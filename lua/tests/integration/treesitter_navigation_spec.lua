-- Integration tests for treesitter-textobjects navigation
-- Verifies no keybinding conflicts with nap.nvim and movement works correctly

local MiniTest = require("mini.test")
local helpers = require("tests.helpers")

local T = MiniTest.new_set({
    hooks = {
        pre_case = function()
            -- Clean up buffers between tests
            for _, buf in ipairs(vim.api.nvim_list_bufs()) do
                if vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].buftype == "" then
                    pcall(vim.api.nvim_buf_delete, buf, { force = true })
                end
            end
        end,
    },
})

T["keybinding conflicts"] = MiniTest.new_set()

T["keybinding conflicts"]["no duplicate ] keymaps"] = function()
    local seen_keys = {}
    local duplicates = {}

    -- Get all normal mode ] keymaps
    local keymaps = vim.api.nvim_get_keymap("n")
    for _, map in ipairs(keymaps) do
        local key = map.lhs
        if key:match("^%]") then
            if seen_keys[key] then
                table.insert(duplicates, key)
            else
                seen_keys[key] = true
            end
        end
    end

    MiniTest.expect.equality(#duplicates, 0, "Should have no duplicate ] keymaps: " .. vim.inspect(duplicates))
end

T["keybinding conflicts"]["no duplicate [ keymaps"] = function()
    local seen_keys = {}
    local duplicates = {}

    -- Get all normal mode [ keymaps
    local keymaps = vim.api.nvim_get_keymap("n")
    for _, map in ipairs(keymaps) do
        local key = map.lhs
        if key:match("^%[") then
            if seen_keys[key] then
                table.insert(duplicates, key)
            else
                seen_keys[key] = true
            end
        end
    end

    MiniTest.expect.equality(#duplicates, 0, "Should have no duplicate [ keymaps: " .. vim.inspect(duplicates))
end

T["keybinding conflicts"]["treesitter and nap coexist"] = function()
    -- Create a treesitter-enabled buffer to trigger textobject keymaps
    local content = { "function test()", "  return 1", "end" }
    local bufnr = helpers.create_test_buffer(content, "lua")

    -- Wait for treesitter to attach and set up keymaps
    vim.wait(1000, function()
        local buf_keymaps = vim.api.nvim_buf_get_keymap(bufnr, "n")
        for _, map in ipairs(buf_keymaps) do
            if map.lhs == "]m" then return true end
        end
        return false
    end)

    -- Get buffer-local keymaps (treesitter) and global keymaps (nap)
    local buf_keymaps = vim.api.nvim_buf_get_keymap(bufnr, "n")
    local global_keymaps = vim.api.nvim_get_keymap("n")

    local has_treesitter_m = false
    local has_treesitter_z = false
    local has_treesitter_k = false

    -- Check treesitter keymaps (buffer-local)
    for _, map in ipairs(buf_keymaps) do
        if map.lhs == "]m" then has_treesitter_m = true end
        if map.lhs == "]z" then has_treesitter_z = true end
        if map.lhs == "]k" then has_treesitter_k = true end
    end

    local has_nap_a = false
    local has_nap_f = false
    local has_nap_b = false

    -- Check nap keymaps (global)
    for _, map in ipairs(global_keymaps) do
        if map.lhs == "]a" then has_nap_a = true end
        if map.lhs == "]f" then has_nap_f = true end
        if map.lhs == "]b" then has_nap_b = true end
    end

    MiniTest.expect.equality(has_treesitter_m, true, "Should have ]m (treesitter methods)")
    MiniTest.expect.equality(has_treesitter_z, true, "Should have ]z (treesitter arguments)")
    MiniTest.expect.equality(has_treesitter_k, true, "Should have ]k (treesitter blocks)")
    MiniTest.expect.equality(has_nap_a, true, "Should have ]a (nap tabs)")
    MiniTest.expect.equality(has_nap_f, true, "Should have ]f (nap files)")
    MiniTest.expect.equality(has_nap_b, true, "Should have ]b (nap buffers)")

    helpers.delete_buffer(bufnr)
end

T["treesitter movement"] = MiniTest.new_set()

T["treesitter movement"]["navigate methods with ]m"] = function()
    local content = {
        "function first()",
        "  return 1",
        "end",
        "",
        "function second()",
        "  return 2",
        "end",
    }
    local bufnr = helpers.create_test_buffer(content, "lua")

    -- Set cursor to first line
    vim.api.nvim_win_set_cursor(0, { 1, 0 })

    -- Jump to next method
    vim.cmd("normal ]m")

    -- Should be at second function
    local cursor = vim.api.nvim_win_get_cursor(0)
    MiniTest.expect.equality(cursor[1], 5, "Cursor should be at line 5 (second function)")

    helpers.delete_buffer(bufnr)
end

T["treesitter movement"]["navigate arguments with ]z"] = function()
    local content = {
        "function test(arg1, arg2, arg3)",
        "  return arg1 + arg2 + arg3",
        "end",
    }
    local bufnr = helpers.create_test_buffer(content, "lua")

    -- Set cursor at function name
    vim.api.nvim_win_set_cursor(0, { 1, 0 })

    -- Jump to first argument
    vim.cmd("normal ]z")

    -- Cursor should be in argument list
    local cursor = vim.api.nvim_win_get_cursor(0)
    MiniTest.expect.equality(cursor[1], 1, "Cursor should still be on line 1")
    -- Just verify it moved (exact position depends on treesitter)
    local moved = cursor[2] > 0
    MiniTest.expect.equality(moved, true, "Cursor should have moved into arguments")

    helpers.delete_buffer(bufnr)
end

T["treesitter movement"]["navigate blocks with ]k"] = function()
    local content = {
        "if true then",
        "  print('first')",
        "end",
        "",
        "if false then",
        "  print('second')",
        "end",
    }
    local bufnr = helpers.create_test_buffer(content, "lua")

    -- Set cursor to first line
    vim.api.nvim_win_set_cursor(0, { 1, 0 })

    -- Jump to next block
    vim.cmd("normal ]k")

    -- Should be at second if statement
    local cursor = vim.api.nvim_win_get_cursor(0)
    MiniTest.expect.equality(cursor[1], 5, "Cursor should be at line 5 (second block)")

    helpers.delete_buffer(bufnr)
end

T["treesitter selection"] = MiniTest.new_set()

T["treesitter selection"]["select method with am"] = function()
    local content = {
        "function test()",
        "  return 1",
        "end",
    }
    local bufnr = helpers.create_test_buffer(content, "lua")

    -- Set cursor inside function
    vim.api.nvim_win_set_cursor(0, { 2, 2 })

    -- Select around method
    vim.cmd("normal vam")

    -- Should have visual selection
    local mode = vim.fn.mode()
    MiniTest.expect.equality(mode == "v" or mode == "V", true, "Should be in visual mode")

    -- Exit visual mode
    vim.cmd("normal \27")

    helpers.delete_buffer(bufnr)
end

T["treesitter selection"]["select argument with az"] = function()
    local content = {
        "function test(arg1, arg2)",
        "  return arg1",
        "end",
    }
    local bufnr = helpers.create_test_buffer(content, "lua")

    -- Set cursor on first argument
    vim.api.nvim_win_set_cursor(0, { 1, 15 })

    -- Select around argument
    vim.cmd("normal vaz")

    -- Should have visual selection
    local mode = vim.fn.mode()
    MiniTest.expect.equality(mode == "v" or mode == "V", true, "Should be in visual mode")

    -- Exit visual mode
    vim.cmd("normal \27")

    helpers.delete_buffer(bufnr)
end

T["treesitter swap"] = MiniTest.new_set()

T["treesitter swap"]["swap methods with >M"] = function()
    local content = {
        "function first()",
        "  return 1",
        "end",
        "",
        "function second()",
        "  return 2",
        "end",
    }
    local bufnr = helpers.create_test_buffer(content, "lua")

    -- Set cursor in first function
    vim.api.nvim_win_set_cursor(0, { 1, 0 })

    -- Swap with next function
    vim.cmd("normal >M")

    -- Get buffer content
    local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

    -- second() should now be first
    local has_second_first = false
    for i, line in ipairs(lines) do
        if line:match("function second") and i < 5 then
            has_second_first = true
            break
        end
    end

    MiniTest.expect.equality(has_second_first, true, "second() should be swapped to first position")

    helpers.delete_buffer(bufnr)
end

T["nap navigation preserved"] = MiniTest.new_set()

T["nap navigation preserved"]["tabs navigation with ]a"] = function()
    -- Verify ]a is mapped (detailed nap testing not needed, just verify it exists)
    local keymaps = vim.api.nvim_get_keymap("n")
    local has_nap_a = false

    for _, map in ipairs(keymaps) do
        if map.lhs == "]a" then
            has_nap_a = true
            break
        end
    end

    MiniTest.expect.equality(has_nap_a, true, "Should have ]a keybinding for nap tabs")
end

T["nap navigation preserved"]["files navigation with ]f"] = function()
    -- Verify ]f is mapped
    local keymaps = vim.api.nvim_get_keymap("n")
    local has_nap_f = false

    for _, map in ipairs(keymaps) do
        if map.lhs == "]f" then
            has_nap_f = true
            break
        end
    end

    MiniTest.expect.equality(has_nap_f, true, "Should have ]f keybinding for nap files")
end

T["nap navigation preserved"]["buffers navigation with ]b"] = function()
    -- Verify ]b is mapped
    local keymaps = vim.api.nvim_get_keymap("n")
    local has_nap_b = false

    for _, map in ipairs(keymaps) do
        if map.lhs == "]b" then
            has_nap_b = true
            break
        end
    end

    MiniTest.expect.equality(has_nap_b, true, "Should have ]b keybinding for nap buffers")
end

if MiniTest.run == nil then MiniTest.run() end

return T
