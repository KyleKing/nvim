-- Test helper utilities for Mini.test
local M = {}
local constants = require("kyleking.utils.constants")

-- Wait for LSP client to attach to buffer
-- @param bufnr number: Buffer number to wait for
-- @param timeout_ms number: Timeout in milliseconds (default: 5000)
-- @return boolean: true if LSP attached, false if timeout
function M.wait_for_lsp_attach(bufnr, timeout_ms)
    timeout_ms = timeout_ms or 5000
    local start_time = vim.uv.now()

    while vim.uv.now() - start_time < timeout_ms do
        local clients = vim.lsp.get_clients({ bufnr = bufnr })
        if #clients > 0 then return true end
        vim.wait(100)
    end

    return false
end

-- Create a test buffer with given lines
-- @param lines table: List of lines to set in buffer
-- @param filetype string: Optional filetype to set
-- @return number: Buffer number
function M.create_test_buffer(lines, filetype)
    local bufnr = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)

    if filetype then
        vim.api.nvim_set_current_buf(bufnr)
        vim.bo[bufnr].filetype = filetype
    end

    return bufnr
end

-- Delete a buffer forcefully
-- @param bufnr number: Buffer number to delete
function M.delete_buffer(bufnr)
    if vim.api.nvim_buf_is_valid(bufnr) then vim.api.nvim_buf_delete(bufnr, { force = true }) end
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
-- @param interval_ms number: Check interval in milliseconds (default: 100)
-- @return boolean: true if condition met, false if timeout
function M.wait_for_condition(fn, timeout_ms, interval_ms)
    timeout_ms = timeout_ms or 2000
    interval_ms = interval_ms or 100
    local start_time = vim.uv.now()

    while vim.uv.now() - start_time < timeout_ms do
        if fn() then return true end
        vim.wait(interval_ms)
    end

    return false
end

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

-- Run a command and wait for completion
-- @param cmd string: Command to run
-- @param timeout_ms number: Timeout in milliseconds (default: 5000)
-- @return boolean: true if command completed, false if timeout
function M.run_command_async(cmd, timeout_ms)
    timeout_ms = timeout_ms or 5000
    local completed = false

    vim.cmd(cmd)
    completed = true

    return completed
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
    vim.cmd("only")

    -- Clear all diagnostics
    vim.diagnostic.reset()

    -- Stop all LSP clients
    for _, client in pairs(vim.lsp.get_clients()) do
        vim.lsp.stop_client(client.id)
    end

    -- Clear test-related autocmds (preserve user config autocmds)
    local test_groups = vim.api.nvim_get_autocmds({ group = "test_*" })
    for _, autocmd in ipairs(test_groups) do
        pcall(vim.api.nvim_del_autocmd, autocmd.id)
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
    for key, _ in pairs(_G) do
        if type(key) == "string" and key:match("^test_") then _G[key] = nil end
    end

    -- Clear loaded test modules from package cache
    for key, _ in pairs(package.loaded) do
        if type(key) == "string" and (key:match("^tests%.") or key:match("_spec$")) then package.loaded[key] = nil end
    end

    -- Force garbage collection to clean up resources
    collectgarbage("collect")

    -- Brief wait for cleanup to settle
    vim.wait(10)
end

--- Run Lua code in a subprocess nvim with full user config loaded.
--- Waits for plugins to initialize, executes the code, then checks for errors.
--- @param lua_code string Lua code to execute after plugins load
--- @param timeout_ms number|nil Subprocess timeout (default: 15000)
--- @return table {code: number, stdout: string, stderr: string}
function M.nvim_interaction_test(lua_code, timeout_ms)
    timeout_ms = timeout_ms or 15000
    local tmpfile = vim.fn.tempname() .. "_interaction_test.lua"

    local sync_mode = vim.env.MINI_DEPS_LATER_AS_NOW ~= nil
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

    if vim.env.MINI_DEPS_LATER_AS_NOW then cmd = { "env", "MINI_DEPS_LATER_AS_NOW=1", unpack(cmd) } end

    local result = vim.system(cmd, opts):wait(timeout_ms)

    vim.fn.delete(tmpfile)

    return {
        code = result.code,
        stdout = result.stdout or "",
        stderr = result.stderr or "",
    }
end

return M
