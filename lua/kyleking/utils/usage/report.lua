-- Aggregate the per-host JSONL logs into usage counts.

local M = {}

local DEFAULT_LIMIT = 40

--- Sum events across every host file in `dir`, ranked by count then key.
--- Malformed lines are skipped so a partially written batch cannot break the report.
---@param dir string
---@return table[] rows {kind, key, desc, count, last}
function M.aggregate(dir)
    local rows = {}

    for _, path in ipairs(vim.fn.glob(dir .. "/*.jsonl", false, true)) do
        if vim.fn.filereadable(path) == 1 then
            for line in io.lines(path) do
                local ok, event = pcall(vim.json.decode, line)
                if ok and type(event) == "table" and type(event.key) == "string" then
                    local id = (event.kind or "?") .. "\0" .. event.key
                    local row = rows[id]
                    if row == nil then
                        row = { kind = event.kind or "?", key = event.key, count = 0, last = 0 }
                        rows[id] = row
                    end
                    row.count = row.count + 1
                    row.last = math.max(row.last, tonumber(event.ts) or 0)
                    row.desc = row.desc or event.desc
                end
            end
        end
    end

    local ranked = vim.tbl_values(rows)
    table.sort(ranked, function(a, b)
        if a.count ~= b.count then return a.count > b.count end
        return a.key < b.key
    end)
    return ranked
end

---@param rows table[]
---@param limit number|nil
---@return string[]
function M.render(rows, limit)
    limit = limit or DEFAULT_LIMIT
    if #rows == 0 then return { "No usage recorded yet." } end

    local lines = { ("Feature usage: top %d of %d"):format(math.min(limit, #rows), #rows), "" }
    for i = 1, math.min(limit, #rows) do
        local row = rows[i]
        local last = row.last > 0 and os.date("%Y-%m-%d", row.last) or "?"
        lines[#lines + 1] = ("%6d  %-7s %-24s %-12s %s"):format(row.count, row.kind, row.key, last, row.desc or "")
    end
    return lines
end

--- Open the report in a scratch buffer.
function M.show(dir)
    local lines = M.render(M.aggregate(dir))
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.bo[buf].modifiable = false
    vim.bo[buf].bufhidden = "wipe"
    vim.api.nvim_win_set_buf(0, buf)
end

return M
