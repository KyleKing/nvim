-- Test helper utilities for Mini.test
local M = {}
local constants = require("kyleking.utils.constants")

-- Shorten mini.surround's unhighlight timer for test runs
-- After a surround operation mini.surround highlights the region and hands the cleanup to
-- vim.defer_fn(_, highlight_duration), 500ms by default. A test finishes and deletes its
-- buffer long before that, and the timer then clears a namespace on a dead buffer. The
-- highlight is a UI nicety that no assertion reads, so tests drop the delay to 0 and
-- M.drain_deferred lets the callback run while the buffer is still valid.
--- Called at module load, before any test can schedule a highlight, and again from
--- drain_deferred. The second call is the backstop: if mini.surround was not set up
--- yet when this file loaded (a task without NVIM_TEST_SYNC, where plugins load
--- deferred), the load-time call is a no-op and only the teardown call catches it.
local function silence_surround_highlight()
    local surround = package.loaded["mini.surround"]
    if surround ~= nil and surround.config ~= nil then surround.config.highlight_duration = 0 end
end

silence_surround_highlight()

-- Wait for LSP client to attach to buffer
-- @param bufnr number: Buffer number to wait for
-- @param timeout_ms number: Timeout in milliseconds (default: 5000)
-- @return boolean: true if LSP attached, false if timeout
function M.wait_for_lsp_attach(bufnr, timeout_ms)
    return vim.wait(timeout_ms or 5000, function() return #vim.lsp.get_clients({ bufnr = bufnr }) > 0 end, 10)
end

-- Return to a clean normal mode, dropping any pending count
-- v:count survives the command that set it, and plugin functions called straight from
-- Lua still read v:count1: MiniMove.move_line("down") after a fixture that left
-- v:count at 1000 moves the line 1000 rows. Tests then fail based on run order.
function M.reset_pending_state() vim.cmd("normal! " .. vim.api.nvim_replace_termcodes("<Esc>", true, false, true)) end

-- Clear 'winfixbuf' from every window
-- mini.files, mini.pick and friends pin their windows to a buffer. A test that leaves
-- one of those windows current makes every later buffer switch fail with E1513, so
-- tests blame whichever case runs next instead of the one that leaked the window.
function M.clear_winfixbuf()
    for _, win in ipairs(vim.api.nvim_list_wins()) do
        if vim.api.nvim_win_is_valid(win) and vim.wo[win].winfixbuf then vim.wo[win].winfixbuf = false end
    end
end

-- Create a test buffer with given lines
-- @param lines table: List of lines to set in buffer
-- @param filetype string: Optional filetype to set
-- @return number: Buffer number
function M.create_test_buffer(lines, filetype)
    local bufnr = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)

    if filetype then
        M.clear_winfixbuf()
        vim.api.nvim_set_current_buf(bufnr)
        vim.bo[bufnr].filetype = filetype
    end

    return bufnr
end

-- Run the event loop until work already queued with vim.schedule or vim.defer_fn(_, 0) has run
-- Those callbacks capture a buffer id and use it later. Deleting the buffer first leaves them
-- holding a dead handle, and they raise "Invalid buffer id" from outside any test case, so
-- nothing fails but the run prints tracebacks to stderr. Two reach us: mini.surround's
-- region_unhighlight, and vim.lsp's start_config, which an autostart schedules on FileType.
-- The marker below is queued behind whatever is already pending, so waiting on it drains the
-- queue with no fixed sleep. Measured at about 0.015ms per call.
function M.drain_deferred()
    silence_surround_highlight()
    local drained = false
    vim.defer_fn(function() drained = true end, 0)
    vim.wait(100, function() return drained end, 1)
end

-- Delete a buffer forcefully
-- @param bufnr number: Buffer number to delete
function M.delete_buffer(bufnr)
    if not vim.api.nvim_buf_is_valid(bufnr) then return end
    M.drain_deferred()
    if vim.api.nvim_buf_is_valid(bufnr) then vim.api.nvim_buf_delete(bufnr, { force = true }) end
end

-- Inspect a mini.pick picker while it is open, then close it
-- MiniPick.start() does not return until the picker closes, and it waits on
-- getcharstr(), which never returns under `nvim --headless`. Queue the stop key
-- before starting so the picker closes on its own, and read its state from the
-- MiniPickStop autocmd, which fires while the picker is still active.
-- @param start_opts table: Options passed to MiniPick.start
-- @param fn function: Called with the picker open; its return value is returned
-- @return any: Whatever fn returned
function M.with_active_picker(start_opts, fn)
    local result
    vim.api.nvim_create_autocmd("User", {
        pattern = "MiniPickStop",
        once = true,
        callback = function() result = fn() end,
    })
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "t", false)
    require("mini.pick").start(start_opts)
    return result
end

-- Check if a keymap exists and matches expected description
-- @param lhs string: Left-hand side of keymap
-- @param mode string: Mode (n, i, v, etc.)
-- @param expected_desc string: Expected description (optional)
-- @return boolean, table: exists, keymap_info
function M.check_keymap(lhs, mode, expected_desc)
    local keymap = vim.fn.maparg(lhs, mode, false, true)
    local exists = keymap ~= nil and keymap.lhs ~= nil

    if expected_desc and exists then return keymap.desc == expected_desc, keymap end

    return exists, keymap
end

-- Wait for a condition to be true
-- @param fn function: Function to check (should return boolean)
-- @param timeout_ms number: Timeout in milliseconds (default: 2000)
-- @param interval_ms number: Check interval in milliseconds (default: 10)
-- @return boolean: true if condition met, false if timeout
function M.wait_for_condition(fn, timeout_ms, interval_ms) return vim.wait(timeout_ms or 2000, fn, interval_ms or 10) end

-- Wait for autocmd to be registered
-- @param event string: Event name
-- @param pattern string: Pattern to match
-- @param timeout_ms number: Timeout in milliseconds (default: 2000)
-- @return boolean: true if autocmd found, false if timeout
function M.wait_for_autocmd(event, pattern, timeout_ms)
    return M.wait_for_condition(function()
        local autocmds = vim.api.nvim_get_autocmds({
            event = event,
            pattern = pattern,
        })
        return #autocmds > 0
    end, timeout_ms)
end

-- Get diagnostic count for buffer
-- @param bufnr number: Buffer number (default: current buffer)
-- @param severity string: Severity level (ERROR, WARN, INFO, HINT) or nil for all
-- @return number: Count of diagnostics
function M.get_diagnostic_count(bufnr, severity)
    bufnr = bufnr or vim.api.nvim_get_current_buf()
    local diagnostics

    if severity then
        diagnostics = vim.diagnostic.get(bufnr, { severity = vim.diagnostic.severity[severity] })
    else
        diagnostics = vim.diagnostic.get(bufnr)
    end

    return #diagnostics
end

-- Create a temporary file with content
-- @param content string|table: Content to write (string or lines)
-- @param extension string: File extension (default: "txt")
-- @return string: Path to temporary file
function M.create_temp_file(content, extension)
    extension = extension or "txt"
    local tmpfile = vim.fn.tempname() .. "." .. extension

    if type(content) == "table" then content = table.concat(content, "\n") end

    local f = io.open(tmpfile, "w")
    if f then
        f:write(content)
        f:close()
    end

    return tmpfile
end

-- Clean up temporary file
-- @param filepath string: Path to file to delete
function M.cleanup_temp_file(filepath)
    if vim.fn.filereadable(filepath) == 1 then vim.fn.delete(filepath) end
end

-- Get LSP client by name for buffer
-- @param bufnr number: Buffer number
-- @param name string: Client name to find
-- @return table|nil: Client or nil if not found
function M.get_lsp_client_by_name(bufnr, name)
    local clients = vim.lsp.get_clients({ bufnr = bufnr })
    for _, client in ipairs(clients) do
        if client.name == name then return client end
    end
    return nil
end

-- Check if a plugin is loaded
-- @param plugin_name string: Name of plugin module
-- @return boolean: true if loaded
function M.is_plugin_loaded(plugin_name) return package.loaded[plugin_name] ~= nil end

-- Wait for plugins to load (uses standard plugin load delay)
function M.wait_for_plugins() vim.wait(constants.DELAY.PLUGIN_LOAD) end

-- Wait for a specific plugin to load
-- @param plugin_name string: Name of the plugin module
-- @param timeout_ms number: Timeout in milliseconds (default: DELAY.PLUGIN_LOAD)
-- @return boolean: true if plugin loaded, false if timeout
function M.wait_for_plugin(plugin_name, timeout_ms)
    timeout_ms = timeout_ms or constants.DELAY.PLUGIN_LOAD
    return M.wait_for_condition(function() return M.is_plugin_loaded(plugin_name) end, timeout_ms)
end

-- Reload a module (clear from package.loaded)
-- @param module_name string: Module to reload
function M.reload_module(module_name) package.loaded[module_name] = nil end

-- Get visual selection text
-- @return string: Selected text
function M.get_visual_selection()
    local start_pos = vim.fn.getpos("'<")
    local end_pos = vim.fn.getpos("'>")
    local lines = vim.fn.getline(start_pos[2], end_pos[2])

    if #lines == 0 then return "" end

    -- Handle single line selection
    if #lines == 1 then return string.sub(lines[1], start_pos[3], end_pos[3]) end

    -- Handle multi-line selection
    lines[1] = string.sub(lines[1], start_pos[3])
    lines[#lines] = string.sub(lines[#lines], 1, end_pos[3])

    return table.concat(lines, "\n")
end

-- Set visual selection
-- @param start_line number: Start line
-- @param start_col number: Start column
-- @param end_line number: End line
-- @param end_col number: End column
function M.set_visual_selection(start_line, start_col, end_line, end_col)
    vim.fn.setpos("'<", { 0, start_line, start_col, 0 })
    vim.fn.setpos("'>", { 0, end_line, end_col, 0 })
end

-- Comprehensive cleanup for sequential test execution
-- Resets state between tests to prevent interference
function M.full_cleanup()
    -- Let queued callbacks run before the buffers they reference disappear
    M.drain_deferred()

    -- Delete all user-created buffers (keep scratch buffers from mini.test)
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_valid(buf) then
            local buftype = vim.bo[buf].buftype
            local bufname = vim.api.nvim_buf_get_name(buf)
            -- Delete non-scratch buffers and named scratch buffers
            if buftype == "" or (buftype == "nofile" and bufname ~= "") then
                pcall(vim.api.nvim_buf_delete, buf, { force = true })
            end
        end
    end

    -- Reset to single window
    M.clear_winfixbuf()
    vim.cmd("only")

    -- Clear all diagnostics
    vim.diagnostic.reset()

    -- Stop all LSP clients
    for _, client in pairs(vim.lsp.get_clients()) do
        vim.lsp.stop_client(client.id)
    end

    -- Clear test-related autocmds (preserve user config autocmds)
    -- nvim_get_autocmds takes an exact group name, and errors on a glob, so match by hand
    for _, autocmd in ipairs(vim.api.nvim_get_autocmds({})) do
        if autocmd.group_name and autocmd.group_name:match("^test_") then
            pcall(vim.api.nvim_del_autocmd, autocmd.id)
        end
    end

    -- Clear test keymaps (keymaps starting with <leader>test or containing "test")
    -- Note: This is conservative to avoid clearing user keymaps
    local modes = { "n", "i", "v", "x", "s", "o", "c", "t" }
    for _, mode in ipairs(modes) do
        local keymaps = vim.api.nvim_get_keymap(mode)
        for _, keymap in ipairs(keymaps) do
            if
                keymap.lhs and (keymap.lhs:match("<leader>test") or (keymap.desc and keymap.desc:lower():match("test")))
            then
                pcall(vim.keymap.del, mode, keymap.lhs)
            end
        end
    end

    -- Clear test-specific global variables
    -- selene: allow(global_usage)
    for key, _ in pairs(_G) do
        if type(key) == "string" and key:match("^test_") then _G[key] = nil end
    end

    -- Clear loaded test modules from package cache
    for key, _ in pairs(package.loaded) do
        if type(key) == "string" and (key:match("^tests%.") or key:match("_spec$")) then package.loaded[key] = nil end
    end

    -- Force garbage collection to clean up resources
    collectgarbage("collect")

    -- Let anything the cleanup scheduled run before the next case starts
    M.drain_deferred()
end

--- Run Lua code in a subprocess nvim with full user config loaded.
--- Waits for plugins to initialize, executes the code, then checks for errors.
--- @param lua_code string Lua code to execute after plugins load
--- @param timeout_ms number|nil Subprocess timeout (default: 15000)
--- @return table {code: number, stdout: string, stderr: string}
function M.nvim_interaction_test(lua_code, timeout_ms)
    timeout_ms = timeout_ms or 15000
    local tmpfile = vim.fn.tempname() .. "_interaction_test.lua"

    local sync_mode = vim.env.NVIM_TEST_SYNC ~= nil
    local pre_delay = sync_mode and 100 or 2000
    local post_delay = sync_mode and 50 or 500

    local wrapped = table.concat({
        ("vim.wait(%d, function() return false end)"):format(pre_delay),
        lua_code,
        ("vim.wait(%d, function() return false end)"):format(post_delay),
        "vim.cmd('qall!')",
    }, "\n")

    local f = io.open(tmpfile, "w")
    if f then
        f:write(wrapped)
        f:close()
    end

    local cmd = { "nvim", "--headless", "-c", "luafile " .. tmpfile }
    local opts = { text = true }

    if vim.env.NVIM_TEST_SYNC then cmd = { "env", "NVIM_TEST_SYNC=1", unpack(cmd) } end

    local result = vim.system(cmd, opts):wait(timeout_ms)

    vim.fn.delete(tmpfile)

    return {
        code = result.code,
        stdout = result.stdout or "",
        stderr = result.stderr or "",
    }
end

return M
