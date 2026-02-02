-- Test terminal integration functionality
local MiniTest = require("mini.test")
local helpers = require("tests.helpers")

local T = MiniTest.new_set({
    hooks = {
        pre_case = function()
            -- Clean up any existing terminal state
            local term_mod = require("kyleking.deps.terminal-integration")
            if term_mod.shell_term.bufnr then
                pcall(vim.api.nvim_buf_delete, term_mod.shell_term.bufnr, { force = true })
            end
            if term_mod.shell_term.tabnr and vim.api.nvim_tabpage_is_valid(term_mod.shell_term.tabnr) then
                local tabnum = vim.api.nvim_tabpage_get_number(term_mod.shell_term.tabnr)
                pcall(vim.cmd, "tabclose! " .. tabnum)
            end
            term_mod.shell_term.bufnr = nil
            term_mod.shell_term.tabnr = nil
            term_mod.shell_term.prev_tabnr = nil
        end,
    },
})

T["terminal integration"] = MiniTest.new_set()

T["terminal integration"]["module loads"] = function()
    vim.wait(1000)
    MiniTest.expect.equality(
        helpers.is_plugin_loaded("kyleking.deps.terminal-integration"),
        true,
        "terminal-integration should be loaded"
    )
end

T["terminal integration"]["toggle_shell_tab keymap exists"] = function()
    vim.wait(1000)
    local exists, keymap = helpers.check_keymap("<leader>tt", "n")
    MiniTest.expect.equality(exists, true, "<leader>tt should be mapped")
    MiniTest.expect.equality(keymap.desc:lower():find("terminal") ~= nil, true, "Should be terminal-related mapping")
end

T["terminal integration"]["can open terminal tab"] = function()
    vim.wait(1000)

    local initial_tab_count = vim.fn.tabpagenr("$")
    local term_mod = require("kyleking.deps.terminal-integration")

    -- Open terminal
    term_mod.toggle_shell_tab()

    -- Wait for terminal to be created
    vim.wait(500)

    -- Should have one more tab
    local new_tab_count = vim.fn.tabpagenr("$")
    MiniTest.expect.equality(new_tab_count, initial_tab_count + 1, "Should create new tab")

    -- Terminal state should be set
    MiniTest.expect.equality(term_mod.shell_term.bufnr ~= nil, true, "Should have buffer")
    MiniTest.expect.equality(term_mod.shell_term.tabnr ~= nil, true, "Should have tab")
end

T["terminal integration"]["terminal tab auto-closes on exit"] = function()
    vim.wait(1000)

    local initial_tab_count = vim.fn.tabpagenr("$")
    local term_mod = require("kyleking.deps.terminal-integration")

    -- Open terminal
    term_mod.toggle_shell_tab()
    vim.wait(500)

    local tab_count_after_open = vim.fn.tabpagenr("$")
    MiniTest.expect.equality(tab_count_after_open, initial_tab_count + 1, "Should have opened new tab")

    -- Get the terminal channel ID
    local term_bufnr = term_mod.shell_term.bufnr
    local term_tabnr = term_mod.shell_term.tabnr
    MiniTest.expect.equality(term_bufnr ~= nil, true, "Terminal buffer should exist")
    MiniTest.expect.equality(term_tabnr ~= nil, true, "Terminal tab should exist")

    local chan_id = vim.b[term_bufnr].terminal_job_id
    MiniTest.expect.equality(chan_id ~= nil, true, "Should have terminal job ID")

    -- Send exit command to terminal (simulates Ctrl-D)
    vim.fn.chansend(chan_id, "exit\n")

    -- Wait for on_exit callback to process
    vim.wait(2000)

    -- Tab should be closed
    local final_tab_count = vim.fn.tabpagenr("$")
    MiniTest.expect.equality(
        final_tab_count,
        initial_tab_count,
        "Tab should auto-close after exit. Initial: "
            .. initial_tab_count
            .. ", After open: "
            .. tab_count_after_open
            .. ", Final: "
            .. final_tab_count
    )

    -- Terminal state should be reset
    MiniTest.expect.equality(term_mod.shell_term.bufnr, nil, "Buffer state should be reset")
    MiniTest.expect.equality(term_mod.shell_term.tabnr, nil, "Tab state should be reset")
    MiniTest.expect.equality(term_mod.shell_term.prev_tabnr, nil, "Prev tab state should be reset")

    -- Tab should not be in tabline (check that the tab number is invalid)
    MiniTest.expect.equality(
        vim.api.nvim_tabpage_is_valid(term_tabnr),
        false,
        "Terminal tab should be invalid (closed)"
    )
end

-- For manual running
if ... == nil then MiniTest.run() end

return T
