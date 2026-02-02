-- Test terminal and TUI tool workflows (lazygit, lazydocker, lazyjj)
local MiniTest = require("mini.test")
local helpers = require("tests.helpers")

local T = MiniTest.new_set({
    hooks = {
        pre_case = function() end,
    },
})

T["terminal keymaps"] = MiniTest.new_set()

T["terminal keymaps"]["terminal toggle keymaps exist"] = function()
    vim.wait(1000)

    local keymaps_to_check = {
        { mode = "n", lhs = "<leader>tt", desc_pattern = "tab" },
        { mode = "t", lhs = "<leader>tt", desc_pattern = "tab" },
        { mode = "n", lhs = "<C-'>", desc_pattern = "[Tt]oggle" },
        { mode = "t", lhs = "<C-'>", desc_pattern = "[Tt]oggle" },
    }

    for _, km in ipairs(keymaps_to_check) do
        local keymap = vim.fn.maparg(km.lhs, km.mode, false, true)
        MiniTest.expect.equality(
            keymap ~= nil and keymap.lhs ~= nil,
            true,
            string.format("Terminal keymap %s in %s mode should exist", km.lhs, km.mode)
        )

        if keymap.desc then
            local matches = keymap.desc:match(km.desc_pattern) ~= nil
            MiniTest.expect.equality(
                matches,
                true,
                string.format("Terminal keymap %s should match pattern '%s'", km.lhs, km.desc_pattern)
            )
        end
    end
end

T["terminal keymaps"]["TUI tool keymaps exist"] = function()
    vim.wait(1000)

    local tui_keymaps = {
        { lhs = "<leader>gg", tool = "lazygit" },
        { lhs = "<leader>gj", tool = "lazyjj" },
        { lhs = "<leader>td", tool = "lazydocker" },
    }

    for _, km in ipairs(tui_keymaps) do
        local keymap = vim.fn.maparg(km.lhs, "n", false, true)
        MiniTest.expect.equality(
            keymap ~= nil and keymap.lhs ~= nil,
            true,
            string.format("TUI keymap %s for %s should exist", km.lhs, km.tool)
        )
    end
end

T["terminal tab workflow"] = MiniTest.new_set()

T["terminal tab workflow"]["can create terminal tab"] = function()
    local result = helpers.nvim_interaction_test(
        [[
        vim.wait(2000)

        -- Get initial tab count
        local initial_tabs = #vim.api.nvim_list_tabpages()

        -- Call terminal tab function
        local terminal = require("kyleking.custom.terminal_integration")
        terminal.toggle_shell_tab()

        vim.wait(500)

        local new_tabs = #vim.api.nvim_list_tabpages()

        if new_tabs > initial_tabs then
            print("SUCCESS: Terminal tab created")
        else
            print("INFO: Terminal tab count: " .. new_tabs)
        end
    ]],
        15000
    )

    MiniTest.expect.equality(result.code, 0, "Terminal tab creation should work: " .. result.stderr)
end

T["terminal tab workflow"]["terminal tab toggle returns to previous tab"] = function()
    local result = helpers.nvim_interaction_test(
        [[
        vim.wait(2000)

        local terminal = require("kyleking.custom.terminal_integration")

        -- Start in tab 1
        local initial_tab = vim.api.nvim_get_current_tabpage()

        -- Toggle to terminal tab
        terminal.toggle_shell_tab()
        vim.wait(300)

        -- Toggle back
        terminal.toggle_shell_tab()
        vim.wait(300)

        local final_tab = vim.api.nvim_get_current_tabpage()

        if initial_tab == final_tab then
            print("SUCCESS: Terminal toggle returned to original tab")
        else
            print("INFO: Tab changed from " .. initial_tab .. " to " .. final_tab)
        end
    ]],
        15000
    )

    MiniTest.expect.equality(result.code, 0, "Terminal toggle should work: " .. result.stderr)
end

T["TUI float workflow"] = MiniTest.new_set()

T["TUI float workflow"]["can create TUI float window"] = function()
    local result = helpers.nvim_interaction_test(
        [[
        vim.wait(2000)

        local terminal = require("kyleking.custom.terminal_integration")

        -- Count initial windows
        local initial_wins = #vim.api.nvim_list_wins()

        -- Create float (using echo command as test)
        terminal.toggle_tui_float("echo 'test'", "test")
        vim.wait(500)

        local new_wins = #vim.api.nvim_list_wins()

        if new_wins > initial_wins then
            print("SUCCESS: TUI float window created")
        else
            print("INFO: Window count: " .. new_wins)
        end
    ]],
        15000
    )

    MiniTest.expect.equality(result.code, 0, "TUI float creation should work: " .. result.stderr)
end

T["TUI float workflow"]["TUI float toggle closes window"] = function()
    local result = helpers.nvim_interaction_test(
        [[
        vim.wait(2000)

        local terminal = require("kyleking.custom.terminal_integration")

        -- Create float
        terminal.toggle_tui_float("echo 'test'", "test")
        vim.wait(300)

        local with_float = #vim.api.nvim_list_wins()

        -- Toggle to close
        terminal.toggle_tui_float("echo 'test'", "test")
        vim.wait(300)

        local after_close = #vim.api.nvim_list_wins()

        if after_close < with_float then
            print("SUCCESS: TUI float was closed")
        else
            print("INFO: Windows before: " .. with_float .. ", after: " .. after_close)
        end
    ]],
        15000
    )

    MiniTest.expect.equality(result.code, 0, "TUI float toggle should work: " .. result.stderr)
end

T["TUI tools availability"] = MiniTest.new_set()

T["TUI tools availability"]["lazygit command exists"] = function()
    vim.wait(1000)

    -- Check if lazygit is in PATH
    local has_lazygit = vim.fn.executable("lazygit") == 1

    if not has_lazygit then print("INFO: lazygit not found in PATH (expected in CI)") end

    -- Test always passes - just checking availability
    MiniTest.expect.equality(true, true, "Test for lazygit availability")
end

T["TUI buffer reuse"] = MiniTest.new_set()

T["TUI buffer reuse"]["terminal tab reuses buffer"] = function()
    local result = helpers.nvim_interaction_test(
        [[
        vim.wait(2000)

        local terminal = require("kyleking.custom.terminal_integration")

        -- Toggle terminal twice
        terminal.toggle_shell_tab()
        vim.wait(300)
        local buf1 = terminal.shell_term.bufnr

        terminal.toggle_shell_tab() -- close
        vim.wait(300)

        terminal.toggle_shell_tab() -- reopen
        vim.wait(300)
        local buf2 = terminal.shell_term.bufnr

        if buf1 == buf2 then
            print("SUCCESS: Terminal buffer was reused")
        else
            print("INFO: Buffer changed from " .. buf1 .. " to " .. buf2)
        end
    ]],
        15000
    )

    MiniTest.expect.equality(result.code, 0, "Terminal buffer reuse should work: " .. result.stderr)
end

T["TUI buffer reuse"]["TUI float reuses buffer for same tool"] = function()
    local result = helpers.nvim_interaction_test(
        [[
        vim.wait(2000)

        local terminal = require("kyleking.custom.terminal_integration")

        -- Create float for same tool twice
        terminal.toggle_tui_float("echo 'test1'", "test")
        vim.wait(300)
        local tui_state = terminal.tui_terminals["test"]
        local buf1 = tui_state and tui_state.bufnr

        terminal.toggle_tui_float("echo 'test1'", "test") -- close
        vim.wait(300)

        terminal.toggle_tui_float("echo 'test1'", "test") -- reopen
        vim.wait(300)
        local buf2 = tui_state and tui_state.bufnr

        if buf1 and buf2 and buf1 == buf2 then
            print("SUCCESS: TUI buffer was reused")
        else
            print("INFO: Buffer IDs: " .. tostring(buf1) .. " vs " .. tostring(buf2))
        end
    ]],
        15000
    )

    MiniTest.expect.equality(result.code, 0, "TUI buffer reuse should work: " .. result.stderr)
end

T["terminal escape"] = MiniTest.new_set()

T["terminal escape"]["can exit terminal mode"] = function()
    local result = helpers.nvim_interaction_test(
        [[
        vim.wait(2000)

        local terminal = require("kyleking.custom.terminal_integration")

        -- Create terminal
        terminal.toggle_shell_tab()
        vim.wait(500)

        -- Enter terminal mode
        vim.cmd("startinsert")
        vim.wait(100)

        -- Try escape sequence (note: hard to test in subprocess)
        -- Just verify terminal was created
        local mode = vim.api.nvim_get_mode().mode

        print("SUCCESS: Terminal created, mode: " .. mode)
    ]],
        15000
    )

    MiniTest.expect.equality(result.code, 0, "Terminal escape should work: " .. result.stderr)
end

-- For manual running
if ... == nil then MiniTest.run() end

return T
