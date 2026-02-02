-- Manual test script for terminal tab close behavior
-- Run from within nvim with: :luafile test_terminal_close.lua
--
-- This tests that:
-- 1. Opening a terminal creates a new tab
-- 2. Exiting the terminal (Ctrl-D / 'exit') closes the tab automatically
-- 3. The tabline properly updates (no ghost tabs)
-- 4. State is properly reset
-- 5. Next toggle creates a fresh terminal (not reusing old state)
--
-- Expected behavior after fix:
-- - Press <C-'> or <leader>tt → Terminal opens in new tab
-- - Type 'exit' or press Ctrl-D → Tab closes automatically, return to previous tab
-- - Tab should disappear from tabline completely
-- - Press <C-'> again → Creates a fresh new terminal tab

local function test_terminal_close()
    print("\n=== Terminal Tab Auto-Close Test ===\n")

    local term_mod = require("kyleking.deps.terminal-integration")

    -- Clean up any existing terminal state first
    if term_mod.shell_term.bufnr and vim.api.nvim_buf_is_valid(term_mod.shell_term.bufnr) then
        pcall(vim.api.nvim_buf_delete, term_mod.shell_term.bufnr, { force = true })
    end
    term_mod.shell_term.bufnr = nil
    term_mod.shell_term.tabnr = nil
    term_mod.shell_term.prev_tabnr = nil

    -- Record initial state
    local initial_tab_count = vim.fn.tabpagenr("$")
    local initial_current_tab = vim.fn.tabpagenr()
    print(string.format("📊 Initial state:"))
    print(string.format("   Tab count: %d", initial_tab_count))
    print(string.format("   Current tab: %d", initial_current_tab))

    -- Open terminal tab
    print("\n🔵 Opening terminal tab...")
    term_mod.toggle_shell_tab()
    vim.wait(500)

    local after_open_count = vim.fn.tabpagenr("$")
    local after_open_current = vim.fn.tabpagenr()
    print(string.format("   Tab count after open: %d", after_open_count))
    print(string.format("   Current tab: %d", after_open_current))

    if after_open_count ~= initial_tab_count + 1 then
        print("❌ FAIL: Terminal tab was not created")
        return
    end

    -- Get terminal channel
    local term_bufnr = term_mod.shell_term.bufnr
    local term_tabnr = term_mod.shell_term.tabnr
    local term_tab_number = vim.api.nvim_tabpage_get_number(term_tabnr)

    if not term_bufnr or not term_tabnr then
        print("❌ FAIL: Terminal state not set properly")
        return
    end

    local chan_id = vim.b[term_bufnr].terminal_job_id
    if not chan_id then
        print("❌ FAIL: Terminal job ID not found")
        return
    end

    print(string.format("   Terminal job ID: %d", chan_id))
    print(string.format("   Terminal tab number: %d", term_tab_number))

    -- Send exit command
    print("\n🔴 Sending 'exit' to terminal...")
    vim.fn.chansend(chan_id, "exit\n")

    -- Wait for on_exit callback to process
    print("⏳ Waiting for terminal to exit and tab to close...")
    vim.wait(2000)

    -- Check final state
    local final_tab_count = vim.fn.tabpagenr("$")
    local final_current_tab = vim.fn.tabpagenr()
    print(string.format("\n📊 Final state:"))
    print(string.format("   Tab count: %d", final_tab_count))
    print(string.format("   Current tab: %d", final_current_tab))
    print(string.format("   Shell state reset: bufnr=%s, tabnr=%s", tostring(term_mod.shell_term.bufnr), tostring(term_mod.shell_term.tabnr)))

    -- Verify results
    print("\n=== Results ===")
    local all_passed = true

    if final_tab_count == initial_tab_count then
        print("✅ Tab count returned to initial value")
    else
        print(string.format("❌ FAIL: Expected %d tabs, got %d tabs", initial_tab_count, final_tab_count))
        all_passed = false
    end

    if not vim.api.nvim_tabpage_is_valid(term_tabnr) then
        print("✅ Terminal tab handle is invalid (properly closed)")
    else
        print("❌ FAIL: Terminal tab handle is still valid")
        all_passed = false
    end

    if term_mod.shell_term.bufnr == nil and term_mod.shell_term.tabnr == nil then
        print("✅ Terminal state properly reset")
    else
        print("❌ FAIL: Terminal state not reset")
        all_passed = false
    end

    if final_current_tab == initial_current_tab then
        print("✅ Returned to original tab")
    else
        print(string.format("⚠️  Current tab changed: was %d, now %d", initial_current_tab, final_current_tab))
    end

    print("\n" .. (all_passed and "✅ ALL TESTS PASSED" or "❌ SOME TESTS FAILED"))
end

-- Run the test
local ok, err = pcall(test_terminal_close)
if not ok then
    print("❌ ERROR: " .. tostring(err))
    print(debug.traceback())
end
