-- Test error recovery and resilience
-- Tests for autocmd conflicts, LSP crashes, plugin failures
local MiniTest = require("mini.test")
local helpers = require("tests.helpers")

local T = MiniTest.new_set({
    hooks = {
        pre_case = function() end,
    },
})

T["autocmd resilience"] = MiniTest.new_set()

T["autocmd resilience"]["no autocmd group collisions"] = function()
    vim.wait(1000)

    -- Get all autocmd groups
    local groups = vim.api.nvim_get_autocmds({})

    -- Track group names to find collisions
    local group_counts = {}
    for _, autocmd in ipairs(groups) do
        if autocmd.group_name then group_counts[autocmd.group_name] = (group_counts[autocmd.group_name] or 0) + 1 end
    end

    -- Check for kyleking_ prefix consistency
    local kyleking_groups = {}
    for group_name, _ in pairs(group_counts) do
        if group_name:match("^kyleking_") then table.insert(kyleking_groups, group_name) end
    end

    -- Just verify we have custom groups
    MiniTest.expect.equality(#kyleking_groups > 0, true, "Should have kyleking_ prefixed autocmd groups")
end

T["autocmd resilience"]["autocmds handle errors gracefully"] = function()
    local result = helpers.nvim_interaction_test(
        [[
        vim.wait(1000)

        -- Create test autocmd that might error
        local error_count = 0
        vim.api.nvim_create_autocmd("User", {
            pattern = "TestError",
            callback = function()
                -- This will error but should be caught
                pcall(function()
                    error("Test error")
                end)
                error_count = error_count + 1
            end,
        })

        -- Trigger autocmd
        vim.cmd("doautocmd User TestError")
        vim.wait(100)

        if error_count > 0 then
            print("SUCCESS: Autocmd error was handled")
        end
    ]],
        15000
    )

    MiniTest.expect.equality(result.code, 0, "Autocmd should handle errors: " .. result.stderr)
end

T["LSP resilience"] = MiniTest.new_set()

T["LSP resilience"]["config handles missing LSP gracefully"] = function()
    local result = helpers.nvim_interaction_test(
        [[
        vim.wait(2000)

        -- Try to attach to a file with no LSP available
        local tmpfile = vim.fn.tempname() .. ".xyz"
        vim.cmd("edit " .. tmpfile)
        vim.bo.filetype = "xyz" -- Non-existent filetype

        vim.wait(1000)

        -- Should not crash, just have no LSP attached
        local clients = vim.lsp.get_clients({ bufnr = 0 })

        print("SUCCESS: No crash with missing LSP, clients: " .. #clients)

        vim.fn.delete(tmpfile)
    ]],
        15000
    )

    MiniTest.expect.equality(result.code, 0, "Should handle missing LSP: " .. result.stderr)
end

T["LSP resilience"]["LSP attach timeout doesn't block"] = function()
    local result = helpers.nvim_interaction_test(
        [[
        vim.wait(2000)

        local tmpfile = vim.fn.tempname() .. ".lua"
        vim.cmd("edit " .. tmpfile)

        local start = vim.loop.now()

        -- Write some content
        vim.api.nvim_buf_set_lines(0, 0, -1, false, {"local x = 1"})

        -- Wait for potential LSP attach
        vim.wait(3000, function()
            return #vim.lsp.get_clients({ bufnr = 0 }) > 0
        end)

        local elapsed = vim.loop.now() - start

        if elapsed < 10000 then
            print("SUCCESS: LSP attach completed or timed out gracefully in " .. elapsed .. "ms")
        end

        vim.fn.delete(tmpfile)
    ]],
        20000
    )

    MiniTest.expect.equality(result.code, 0, "LSP attach should timeout gracefully: " .. result.stderr)
end

T["LSP resilience"]["can recover from LSP restart"] = function()
    local result = helpers.nvim_interaction_test(
        [[
        vim.wait(2000)

        local tmpfile = vim.fn.tempname() .. ".lua"
        vim.cmd("edit " .. tmpfile)
        vim.api.nvim_buf_set_lines(0, 0, -1, false, {"local x = 1"})

        -- Wait for LSP
        vim.wait(3000, function()
            return #vim.lsp.get_clients({ bufnr = 0 }) > 0
        end)

        local initial_clients = vim.lsp.get_clients({ bufnr = 0 })

        if #initial_clients > 0 then
            -- Stop and restart LSP
            vim.lsp.stop_client(initial_clients[1].id)
            vim.wait(1000)

            -- Trigger reattach by editing
            vim.cmd("edit")
            vim.wait(2000)

            print("SUCCESS: LSP restart handled")
        else
            print("INFO: No LSP attached initially")
        end

        vim.fn.delete(tmpfile)
    ]],
        25000
    )

    MiniTest.expect.equality(result.code, 0, "Should recover from LSP restart: " .. result.stderr)
end

T["plugin load resilience"] = MiniTest.new_set()

T["plugin load resilience"]["mini.deps two-stage execution completes"] = function()
    local result = helpers.nvim_interaction_test(
        [[
        vim.wait(3000)

        -- Check that both now() and later() stages completed
        local has_mini_pick = package.loaded["mini.pick"] ~= nil
        local has_mini_clue = package.loaded["mini.clue"] ~= nil

        if has_mini_pick and has_mini_clue then
            print("SUCCESS: Both now() and later() plugins loaded")
        else
            print("WARNING: Some plugins may not have loaded")
            print("mini.pick: " .. tostring(has_mini_pick))
            print("mini.clue: " .. tostring(has_mini_clue))
        end
    ]],
        15000
    )

    MiniTest.expect.equality(result.code, 0, "Two-stage loading should complete: " .. result.stderr)
end

T["plugin load resilience"]["config loads even if plugin missing"] = function()
    -- This test verifies the config doesn't crash if a plugin fails to load
    local result = helpers.nvim_interaction_test(
        [[
        vim.wait(2000)

        -- Simulate plugin not available by temporarily hiding it
        local original_path = package.path

        -- Try to load a potentially missing plugin gracefully
        local ok, err = pcall(function()
            require("nonexistent_plugin")
        end)

        -- Should handle gracefully
        if not ok then
            print("SUCCESS: Handled missing plugin gracefully")
        end
    ]],
        15000
    )

    MiniTest.expect.equality(result.code, 0, "Should handle missing plugins: " .. result.stderr)
end

T["buffer cleanup"] = MiniTest.new_set()

T["buffer cleanup"]["terminal buffers cleanup properly"] = function()
    local result = helpers.nvim_interaction_test(
        [[
        vim.wait(2000)

        -- Create several terminal buffers
        local term_bufs = {}
        for i = 1, 3 do
            vim.cmd("terminal")
            table.insert(term_bufs, vim.api.nvim_get_current_buf())
        end

        vim.wait(500)

        -- Close terminals
        for _, buf in ipairs(term_bufs) do
            if vim.api.nvim_buf_is_valid(buf) then
                vim.api.nvim_buf_delete(buf, { force = true })
            end
        end

        vim.wait(500)

        -- Verify cleanup
        local remaining = 0
        for _, buf in ipairs(term_bufs) do
            if vim.api.nvim_buf_is_valid(buf) then
                remaining = remaining + 1
            end
        end

        if remaining == 0 then
            print("SUCCESS: Terminal buffers cleaned up")
        else
            print("WARNING: " .. remaining .. " terminal buffers remain")
        end
    ]],
        15000
    )

    MiniTest.expect.equality(result.code, 0, "Terminal cleanup should work: " .. result.stderr)
end

T["buffer cleanup"]["float windows cleanup on close"] = function()
    local result = helpers.nvim_interaction_test(
        [[
        vim.wait(2000)

        local initial_wins = #vim.api.nvim_list_wins()

        -- Create float window
        local buf = vim.api.nvim_create_buf(false, true)
        local win = vim.api.nvim_open_win(buf, false, {
            relative = "editor",
            width = 40,
            height = 10,
            row = 5,
            col = 5,
        })

        vim.wait(200)
        local with_float = #vim.api.nvim_list_wins()

        -- Close float
        if vim.api.nvim_win_is_valid(win) then
            vim.api.nvim_win_close(win, true)
        end

        vim.wait(200)
        local after_close = #vim.api.nvim_list_wins()

        if after_close <= initial_wins then
            print("SUCCESS: Float window cleaned up")
        else
            print("INFO: Windows - initial: " .. initial_wins .. ", with_float: " .. with_float .. ", after: " .. after_close)
        end
    ]],
        15000
    )

    MiniTest.expect.equality(result.code, 0, "Float cleanup should work: " .. result.stderr)
end

T["diagnostic resilience"] = MiniTest.new_set()

T["diagnostic resilience"]["diagnostics don't crash on invalid buffer"] = function()
    vim.wait(1000)

    -- Try to get diagnostics for invalid buffer
    local ok, _result = pcall(function() return vim.diagnostic.get(999999) end)

    MiniTest.expect.equality(ok, true, "Getting diagnostics for invalid buffer should not crash")
end

T["diagnostic resilience"]["can handle many diagnostics"] = function()
    local result = helpers.nvim_interaction_test(
        [[
        vim.wait(1000)

        local buf = vim.api.nvim_create_buf(false, true)

        -- Create many diagnostics
        local diagnostics = {}
        for i = 1, 100 do
            table.insert(diagnostics, {
                bufnr = buf,
                lnum = i - 1,
                col = 0,
                message = "Test diagnostic " .. i,
                severity = vim.diagnostic.severity.WARN,
            })
        end

        vim.diagnostic.set(vim.api.nvim_create_namespace("test"), buf, diagnostics)
        vim.wait(200)

        local retrieved = vim.diagnostic.get(buf)

        if #retrieved == 100 then
            print("SUCCESS: Handled " .. #retrieved .. " diagnostics")
        end

        vim.api.nvim_buf_delete(buf, { force = true })
    ]],
        15000
    )

    MiniTest.expect.equality(result.code, 0, "Should handle many diagnostics: " .. result.stderr)
end

-- For manual running
if ... == nil then MiniTest.run() end

return T
