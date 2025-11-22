-- Test helpers and utilities for MiniTest
-- Provides reusable helper functions to make tests DRY, maintainable, and parameterized

local M = {}

--- Create a temporary buffer with optional content
--- @param lines table|nil Optional lines to populate the buffer
--- @param filetype string|nil Optional filetype to set
--- @return number bufnr The buffer number
M.create_test_buffer = function(lines, filetype)
    local bufnr = vim.api.nvim_create_buf(false, true)
    if lines then vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines) end
    if filetype then vim.api.nvim_buf_set_option(bufnr, "filetype", filetype) end
    return bufnr
end

--- Delete a buffer forcefully
--- @param bufnr number The buffer number to delete
M.delete_buffer = function(bufnr)
    if vim.api.nvim_buf_is_valid(bufnr) then vim.api.nvim_buf_delete(bufnr, { force = true }) end
end

--- Create a temporary file with content
--- @param content string|table Content to write (string or table of lines)
--- @param extension string|nil File extension (e.g., ".lua", ".py")
--- @return string filepath The path to the temporary file
M.create_temp_file = function(content, extension)
    local tmpdir = vim.fn.tempname()
    vim.fn.mkdir(tmpdir, "p")
    local filepath = tmpdir .. "/test_file" .. (extension or ".txt")

    local lines = type(content) == "table" and content or vim.split(content, "\n")
    vim.fn.writefile(lines, filepath)

    return filepath
end

--- Delete a temporary file or directory
--- @param path string The path to delete
M.delete_temp_path = function(path)
    if vim.fn.isdirectory(path) == 1 then
        vim.fn.delete(path, "rf")
    elseif vim.fn.filereadable(path) == 1 then
        vim.fn.delete(path)
    end
end

--- Check if a keymap exists with expected properties
--- @param mode string The mode (e.g., "n", "v", "i")
--- @param lhs string The left-hand side of the mapping
--- @param expected_desc string|nil Expected description
--- @return boolean exists Whether the keymap exists
--- @return table|nil keymap The keymap table if it exists
M.check_keymap = function(mode, lhs, expected_desc)
    local keymap = vim.fn.maparg(lhs, mode, false, true)
    if vim.tbl_isempty(keymap) then return false, nil end

    if expected_desc and keymap.desc ~= expected_desc then return false, keymap end

    return true, keymap
end

--- Wait for a condition to be true with timeout
--- @param condition function Function that returns true when condition is met
--- @param timeout_ms number Timeout in milliseconds (default 5000)
--- @param interval_ms number Check interval in milliseconds (default 50)
--- @return boolean success Whether the condition was met
M.wait_for = function(condition, timeout_ms, interval_ms)
    timeout_ms = timeout_ms or 5000
    interval_ms = interval_ms or 50
    local elapsed = 0

    while elapsed < timeout_ms do
        if condition() then return true end
        vim.cmd(string.format("sleep %dm", interval_ms))
        elapsed = elapsed + interval_ms
    end

    return false
end

--- Wait for LSP client to attach to buffer
--- @param bufnr number The buffer number
--- @param timeout_ms number Timeout in milliseconds (default 5000)
--- @return boolean success Whether LSP attached
--- @return table|nil clients The attached LSP clients
M.wait_for_lsp = function(bufnr, timeout_ms)
    local success = M.wait_for(function()
        local clients = vim.lsp.get_clients({ bufnr = bufnr })
        return #clients > 0
    end, timeout_ms)

    local clients = vim.lsp.get_clients({ bufnr = bufnr })
    return success, clients
end

--- Get extmarks from a buffer in a namespace
--- @param bufnr number The buffer number
--- @param ns_name string The namespace name
--- @return table extmarks List of extmarks
M.get_extmarks = function(bufnr, ns_name)
    local ns = vim.api.nvim_get_namespaces()[ns_name]
    if not ns then return {} end
    return vim.api.nvim_buf_get_extmarks(bufnr, ns, 0, -1, { details = true })
end

--- Execute a function and capture vim commands/output
--- @param fn function The function to execute
--- @return string output The captured output
M.capture_output = function(fn)
    local output = {}
    local original_echo = vim.api.nvim_echo
    vim.api.nvim_echo = function(chunks, history, opts)
        for _, chunk in ipairs(chunks) do
            table.insert(output, chunk[1])
        end
    end

    local ok, result = pcall(fn)

    vim.api.nvim_echo = original_echo

    return table.concat(output, "\n"), ok, result
end

--- Execute keys in normal mode
--- @param keys string The keys to execute
M.feed_keys = function(keys)
    local termcodes = vim.api.nvim_replace_termcodes(keys, true, false, true)
    vim.api.nvim_feedkeys(termcodes, "x", false)
end

--- Set buffer content and cursor position
--- @param bufnr number The buffer number
--- @param lines table Lines to set
--- @param cursor table|nil Cursor position {row, col} (1-indexed row, 0-indexed col)
M.set_buffer_content = function(bufnr, lines, cursor)
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
    if cursor then
        local win = vim.fn.bufwinid(bufnr)
        if win ~= -1 then vim.api.nvim_win_set_cursor(win, cursor) end
    end
end

--- Get current buffer content
--- @param bufnr number The buffer number
--- @return table lines The buffer lines
M.get_buffer_content = function(bufnr) return vim.api.nvim_buf_get_lines(bufnr, 0, -1, false) end

--- Check if a plugin is loaded
--- @param plugin_name string The plugin module name
--- @return boolean loaded Whether the plugin is loaded
M.is_plugin_loaded = function(plugin_name) return package.loaded[plugin_name] ~= nil end

--- Reload a module (useful for testing module initialization)
--- @param module_name string The module name to reload
M.reload_module = function(module_name) package.loaded[module_name] = nil end

--- Create a test autocmd and verify it exists
--- @param event string|table The event(s) to listen for
--- @param pattern string The pattern to match
--- @param callback_check function Function to check if the autocmd matches
--- @return boolean found Whether a matching autocmd was found
M.check_autocmd = function(event, pattern, callback_check)
    local autocmds = vim.api.nvim_get_autocmds({
        event = event,
        pattern = pattern,
    })

    for _, autocmd in ipairs(autocmds) do
        if callback_check(autocmd) then return true end
    end

    return false
end

--- Run a test with a fresh buffer and clean up afterward
--- @param test_fn function The test function that receives a buffer number
--- @param lines table|nil Optional initial buffer content
--- @param filetype string|nil Optional filetype
M.with_buffer = function(test_fn, lines, filetype)
    local bufnr = M.create_test_buffer(lines, filetype)
    vim.api.nvim_set_current_buf(bufnr)

    local ok, err = pcall(test_fn, bufnr)

    M.delete_buffer(bufnr)

    if not ok then error(err) end
end

--- Run a test with a temporary file and clean up afterward
--- @param test_fn function The test function that receives a filepath
--- @param content string|table Initial file content
--- @param extension string|nil File extension
M.with_temp_file = function(test_fn, content, extension)
    local filepath = M.create_temp_file(content, extension)

    local ok, err = pcall(test_fn, filepath)

    -- Extract directory from filepath
    local dir = vim.fn.fnamemodify(filepath, ":h")
    M.delete_temp_path(dir)

    if not ok then error(err) end
end

--- Assert that a value equals expected (with better error messages)
--- @param actual any The actual value
--- @param expected any The expected value
--- @param msg string Error message
M.assert_equals = function(actual, expected, msg)
    local MiniTest = require("mini.test")
    MiniTest.expect.equality(actual, expected, msg)
end

--- Assert that a condition is true
--- @param condition boolean The condition to check
--- @param msg string Error message
M.assert_true = function(condition, msg)
    local MiniTest = require("mini.test")
    MiniTest.expect.equality(condition, true, msg)
end

--- Assert that a condition is false
--- @param condition boolean The condition to check
--- @param msg string Error message
M.assert_false = function(condition, msg)
    local MiniTest = require("mini.test")
    MiniTest.expect.equality(condition, false, msg)
end

--- Assert that a table contains a value
--- @param tbl table The table to search
--- @param value any The value to find
--- @param msg string Error message
M.assert_contains = function(tbl, value, msg)
    local MiniTest = require("mini.test")
    local found = vim.tbl_contains(tbl, value)
    MiniTest.expect.equality(found, true, msg or ("Table should contain value: " .. vim.inspect(value)))
end

--- Assert that a value is not nil
--- @param value any The value to check
--- @param msg string Error message
M.assert_not_nil = function(value, msg)
    local MiniTest = require("mini.test")
    MiniTest.expect.equality(value ~= nil, true, msg or "Value should not be nil")
end

return M
