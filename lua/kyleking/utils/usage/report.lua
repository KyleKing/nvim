-- Aggregate the per-host logs into usage counts, merging raw events with the compacted
-- summaries of expired months.

local patterns = require("kyleking.utils.usage.patterns")
local store = require("kyleking.utils.usage.store")

local M = {}

local DEFAULT_LIMIT = 40

--- Sum every host file and summary in `dir`, ranked by count then key.
--- Denied keys are dropped and grouped keys collapse under their pattern, so editing
--- patterns.json changes the report without touching stored data.
---@param dir string
---@return table[] rows {kind, key, count, last, desc}
function M.aggregate(dir)
    local active = patterns.load(dir)
    local row_lists = {}

    for _, path in ipairs(store.raw_files(dir)) do
        local rows = store.summarize(store.read_events(path))
        row_lists[#row_lists + 1] = rows
    end

    for _, path in ipairs(store.summary_files(dir)) do
        local summary = store.read_json(path)
        if summary ~= nil and type(summary.rows) == "table" then row_lists[#row_lists + 1] = summary.rows end
    end

    local labeled = {}
    for _, rows in ipairs(row_lists) do
        local kept = {}
        for _, row in ipairs(rows) do
            local label = patterns.label(active, row.key)
            if label ~= nil then kept[#kept + 1] = vim.tbl_extend("force", row, { key = label }) end
        end
        labeled[#labeled + 1] = kept
    end

    local ranked = store.merge_rows(labeled)
    table.sort(ranked, function(a, b)
        if a.count ~= b.count then return a.count > b.count end
        return a.key < b.key
    end)
    return ranked
end

--- Sequences noisy enough to be worth denying, highest count first.
--- Suggestions only: the report never edits patterns.json. Hand-editing it is the whole
--- workflow, which keeps this a pure read and leaves the destructive step deliberate.
--- Only motions qualify, since maps and commands are things I configured on purpose.
---@param rows table[] output of M.aggregate
---@param opts table|nil {min_count, limit}
---@return table[] rows worth denying
function M.noise(rows, opts)
    opts = opts or {}
    local min_count = opts.min_count or 20
    local limit = opts.limit or 10

    local candidates = {}
    for _, row in ipairs(rows) do
        -- A grouped key already collapses a family, so it is signal, not noise.
        if row.kind == "motion" and row.count >= min_count and row.key:find("*", 1, true) == nil then
            candidates[#candidates + 1] = row
            if #candidates >= limit then break end
        end
    end
    return candidates
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

    local noisy = M.noise(rows)
    if #noisy > 0 then
        lines[#lines + 1] = ""
        lines[#lines + 1] = "Noisy motions worth denying (add to patterns.json by hand):"
        for _, row in ipairs(noisy) do
            lines[#lines + 1] = ("  %6d  %s"):format(row.count, row.key)
        end
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
