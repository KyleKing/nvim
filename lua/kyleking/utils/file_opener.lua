local M = {}

---@class FileLocation
---@field path string Absolute file path
---@field line number|nil Line number (1-indexed)
---@field col number|nil Column number (1-indexed)

---Parse file path with optional :line:col suffix
---@param input string Raw input like "file.lua:42:10" or "file.lua:42"
---@param cwd string|nil Working directory for relative paths
---@return FileLocation|nil
function M.parse_file_location(input, cwd)
    cwd = cwd or vim.fn.getcwd()

    local parts = vim.split(input, ":")
    local path = parts[1]
    local line = parts[2] and tonumber(parts[2])
    local col = parts[3] and tonumber(parts[3])

    if not vim.startswith(path, "/") then path = vim.fn.fnamemodify(cwd .. "/" .. path, ":p") end

    if not vim.loop.fs_stat(path) then return nil end

    return { path = path, line = line, col = col }
end

---Open file in new tab with optional line/column jump
---@param location FileLocation
---@param opts table|nil Options {return_to_term: boolean}
function M.open_in_new_tab(location, opts)
    opts = opts or {}

    local term_integration = require("kyleking.deps.terminal-integration")
    local origin_tab = term_integration.shell_term.prev_tabnr

    vim.cmd("tabnew " .. vim.fn.fnameescape(location.path))

    if location.line then
        vim.api.nvim_win_set_cursor(0, { location.line, (location.col or 1) - 1 })
        vim.cmd("normal! zz")
    end

    if opts.return_to_term and origin_tab then vim.g.last_opened_file_tab = vim.api.nvim_get_current_tabpage() end
end

---Open file from terminal buffer with path under cursor or from input
---@param input string|nil File path, defaults to <cfile> under cursor
function M.open_from_terminal(input)
    input = input or vim.fn.expand("<cfile>")

    local term_cwd = vim.b.terminal_job_cwd or vim.fn.getcwd()

    local location = M.parse_file_location(input, term_cwd)
    if not location then
        vim.notify("File not found: " .. input, vim.log.levels.WARN)
        return
    end

    M.open_in_new_tab(location, { return_to_term = true })
end

return M
