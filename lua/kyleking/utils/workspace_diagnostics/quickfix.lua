-- quickfix: operations for filtering, grouping, and analyzing quickfix lists
local M = {}

M.qf = {}

-- Filter quickfix list by pattern
---@param pattern string Pattern to match (vim regex)
---@param keep boolean If true, keep matches; if false, remove matches
function M.qf.filter(pattern, keep)
    local qf = vim.fn.getqflist()
    local filtered = {}

    for _, item in ipairs(qf) do
        local text = item.text or ""
        local matches = text:match(pattern) ~= nil
        if (keep and matches) or (not keep and not matches) then table.insert(filtered, item) end
    end

    vim.fn.setqflist(filtered, "r")
    vim.notify(string.format("Filtered: %d -> %d items", #qf, #filtered), vim.log.levels.INFO)
end

-- Group quickfix items by file
---@return table<string, table[]> items_by_file Map of filename to list of items
function M.qf.group_by_file()
    local qf = vim.fn.getqflist()
    local by_file = {}

    for _, item in ipairs(qf) do
        local filename = vim.fn.bufname(item.bufnr)
        if filename ~= "" then
            if not by_file[filename] then by_file[filename] = {} end
            table.insert(by_file[filename], item)
        end
    end

    return by_file
end

-- Show quickfix statistics
function M.qf.stats()
    local qf = vim.fn.getqflist()
    local by_file = M.qf.group_by_file()
    local by_type = { E = 0, W = 0, I = 0, N = 0 }

    for _, item in ipairs(qf) do
        local type = item.type ~= "" and item.type or "N"
        by_type[type] = (by_type[type] or 0) + 1
    end

    local lines = {
        "Quickfix Statistics:",
        string.format("  Total items: %d", #qf),
        string.format("  Files: %d", vim.tbl_count(by_file)),
        string.format("  Errors: %d | Warnings: %d | Info: %d | Other: %d", by_type.E, by_type.W, by_type.I, by_type.N),
    }

    vim.notify(table.concat(lines, "\n"), vim.log.levels.INFO)
end

-- Remove duplicate quickfix entries (same file + line + text)
function M.qf.dedupe()
    local qf = vim.fn.getqflist()
    local seen = {}
    local deduped = {}

    for _, item in ipairs(qf) do
        local key = string.format("%d:%d:%s", item.bufnr, item.lnum, item.text)
        if not seen[key] then
            seen[key] = true
            table.insert(deduped, item)
        end
    end

    vim.fn.setqflist(deduped, "r")
    vim.notify(string.format("Deduplicated: %d -> %d items", #qf, #deduped), vim.log.levels.INFO)
end

-- Sort quickfix list by file then line number
function M.qf.sort()
    local qf = vim.fn.getqflist()
    table.sort(qf, function(a, b)
        if a.bufnr ~= b.bufnr then return a.bufnr < b.bufnr end
        return a.lnum < b.lnum
    end)

    vim.fn.setqflist(qf, "r")
    vim.notify("Quickfix sorted by file + line", vim.log.levels.INFO)
end

-- Open all files in quickfix list
---@param split_cmd string|nil Split command ("vsplit", "split", "tabnew")
function M.qf.open_all(split_cmd)
    local by_file = M.qf.group_by_file()
    local files = vim.tbl_keys(by_file)
    table.sort(files)

    local cmd = split_cmd or "edit"
    for _, file in ipairs(files) do
        vim.cmd(cmd .. " " .. vim.fn.fnameescape(file))
    end

    vim.notify(string.format("Opened %d files", #files), vim.log.levels.INFO)
end

-- Filter quickfix list by severity type
---@param severity_type string|nil Severity type ("E", "W", "I", "N") or nil for all
function M.qf.filter_severity(severity_type)
    local qf = vim.fn.getqflist()
    local filtered = {}

    for _, item in ipairs(qf) do
        local item_type = item.type ~= "" and item.type or "N"
        if not severity_type or item_type == severity_type then table.insert(filtered, item) end
    end

    vim.fn.setqflist(filtered, "r")
    local label = severity_type and string.format("severity=%s", severity_type) or "all"
    vim.notify(string.format("Filtered to %s: %d -> %d items", label, #qf, #filtered), vim.log.levels.INFO)
end

-- Interactive severity filter with vim.ui.select
function M.qf.filter_severity_interactive()
    local choices = {
        { key = "e", label = "Errors only (E)", type = "E" },
        { key = "w", label = "Warnings only (W)", type = "W" },
        { key = "i", label = "Info only (I)", type = "I" },
        { key = "n", label = "Notes only (N)", type = "N" },
        { key = "a", label = "All (reset filter)", type = nil },
    }

    vim.ui.select(choices, {
        prompt = "Filter by severity:",
        format_item = function(item) return item.label end,
    }, function(choice)
        if choice then M.qf.filter_severity(choice.type) end
    end)
end

-- Group quickfix items by severity type
---@return table<string, table[]> items_by_type Map of type to list of items
function M.qf.group_by_type()
    local qf = vim.fn.getqflist()
    local by_type = {}

    for _, item in ipairs(qf) do
        local type = item.type ~= "" and item.type or "N"
        if not by_type[type] then by_type[type] = {} end
        table.insert(by_type[type], item)
    end

    return by_type
end

return M
