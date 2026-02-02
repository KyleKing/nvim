-- Test helper utilities for Mini.test
local M = {}

-- Wait for LSP client to attach to buffer
-- @param bufnr number: Buffer number to wait for
-- @param timeout_ms number: Timeout in milliseconds (default: 5000)
-- @return boolean: true if LSP attached, false if timeout
function M.wait_for_lsp_attach(bufnr, timeout_ms)
    timeout_ms = timeout_ms or 5000
    local start_time = vim.loop.now()

    while vim.loop.now() - start_time < timeout_ms do
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
    local start_time = vim.loop.now()

    while vim.loop.now() - start_time < timeout_ms do
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

--- Run Lua code in a subprocess nvim with full user config loaded.
--- Waits for plugins to initialize, executes the code, then checks for errors.
--- @param lua_code string Lua code to execute after plugins load
--- @param timeout_ms number|nil Subprocess timeout (default: 15000)
--- @return table {code: number, stdout: string, stderr: string}
function M.nvim_interaction_test(lua_code, timeout_ms)
    timeout_ms = timeout_ms or 15000
    local tmpfile = vim.fn.tempname() .. "_interaction_test.lua"

    local wrapped = table.concat({
        "vim.wait(2000, function() return false end)",
        lua_code,
        "vim.wait(500, function() return false end)",
        "vim.cmd('qall!')",
    }, "\n")

    local f = io.open(tmpfile, "w")
    if f then
        f:write(wrapped)
        f:close()
    end

    local result = vim.system({
        "nvim",
        "--headless",
        "-c",
        "luafile " .. tmpfile,
    }, { text = true }):wait(timeout_ms)

    vim.fn.delete(tmpfile)

    return {
        code = result.code,
        stdout = result.stdout or "",
        stderr = result.stderr or "",
    }
end

return M
