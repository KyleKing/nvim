-- On-disk layout for usage data.
--
--   <host>-YYYY-MM.jsonl        raw events, one month per file
--   summary-<host>-YYYY-MM.json compacted counts for an expired month
--   patterns.json               denylist and groups
--   meta-<host>.json            denylist last applied to this host's stored data
--
-- Monthly files rather than one growing file, and never suffix rotation (.1, .2):
-- a finished month is immutable, so Syncthing transfers it once and never revisits it,
-- while renames would make it re-transfer everything and can manufacture conflicts.

local patterns = require("kyleking.utils.usage.patterns")

local M = {}

---@return string
function M.month_of(ts)
    return os.date("%Y-%m", ts) --[[@as string]]
end

function M.raw_path(dir, host, month) return ("%s/%s-%s.jsonl"):format(dir, host, month) end

function M.summary_path(dir, host, month) return ("%s/summary-%s-%s.json"):format(dir, host, month) end

function M.meta_path(dir, host) return ("%s/meta-%s.json"):format(dir, host) end

--- Split a raw filename into host and month.
--- Anchored on the YYYY-MM suffix because hostnames contain hyphens
--- ("Kyles-MacBook-Pro.local"). Files predating rotation have no month.
---@return string|nil host, string|nil month
function M.parse_raw_name(filename)
    local host, month = filename:match("^(.+)%-(%d%d%d%d%-%d%d)%.jsonl$")
    if host ~= nil then return host, month end
    local legacy = filename:match("^(.+)%.jsonl$")
    return legacy, nil
end

function M.parse_summary_name(filename) return filename:match("^summary%-(.+)%-(%d%d%d%d%-%d%d)%.json$") end

local function read_lines(path)
    local events = {}
    if vim.fn.filereadable(path) == 0 then return events end
    for line in io.lines(path) do
        local ok, event = pcall(vim.json.decode, line)
        if ok and type(event) == "table" and type(event.key) == "string" then events[#events + 1] = event end
    end
    return events
end

M.read_events = read_lines

function M.raw_files(dir) return vim.fn.glob(dir .. "/*.jsonl", false, true) end

function M.summary_files(dir) return vim.fn.glob(dir .. "/summary-*.json", false, true) end

--- Collapse events into per-key counts, the shape a summary file stores.
---@return table[] rows
function M.summarize(events)
    local by_key = {}
    for _, event in ipairs(events) do
        local id = (event.kind or "?") .. "\0" .. event.key
        local row = by_key[id]
        if row == nil then
            row = { kind = event.kind or "?", key = event.key, count = 0, last = 0 }
            by_key[id] = row
        end
        row.count = row.count + 1
        row.last = math.max(row.last, tonumber(event.ts) or 0)
        row.desc = row.desc or event.desc
    end
    return vim.tbl_values(by_key)
end

local function write_json(path, value)
    local fh = assert(io.open(path, "w"))
    fh:write(vim.json.encode(value))
    fh:close()
end

local function read_json(path)
    if vim.fn.filereadable(path) == 0 then return nil end
    local fh = io.open(path, "r")
    if fh == nil then return nil end
    local raw = fh:read("*a")
    fh:close()
    local ok, decoded = pcall(vim.json.decode, raw)
    if not ok then return nil end
    return decoded
end

M.read_json = read_json

--- Month string `n` months before `ts`.
function M.month_before(ts, n)
    local date = os.date("*t", ts) --[[@as osdate]]
    date.month = date.month - n
    date.day = 1
    return os.date("%Y-%m", os.time(date))
end

--- Roll raw monthly files older than the retention window into summaries and delete
--- the raw file. Returns the months compacted.
---@param dir string
---@param opts table {retention_months, now}
---@return string[] compacted
function M.compact(dir, opts)
    local now = opts.now or os.time()
    local cutoff = M.month_before(now, opts.retention_months or 1)
    local compacted = {}

    for _, path in ipairs(M.raw_files(dir)) do
        local host, month = M.parse_raw_name(vim.fn.fnamemodify(path, ":t"))
        -- A legacy file has no month; date it by its newest event so it still compacts.
        local events = read_lines(path)
        if month == nil and #events > 0 then
            local newest = 0
            for _, event in ipairs(events) do
                newest = math.max(newest, tonumber(event.ts) or 0)
            end
            month = M.month_of(newest)
        end

        if host ~= nil and month ~= nil and month <= cutoff then
            local summary_path = M.summary_path(dir, host, month)
            local existing = read_json(summary_path)
            local rows = M.summarize(events)
            if existing ~= nil and type(existing.rows) == "table" then rows = M.merge_rows({ existing.rows, rows }) end
            write_json(summary_path, { host = host, month = month, rows = rows })
            vim.fn.delete(path)
            compacted[#compacted + 1] = month
        end
    end

    return compacted
end

--- Sum several row lists into one, keyed by kind and key.
---@param row_lists table[][]
---@return table[]
function M.merge_rows(row_lists)
    local by_key = {}
    for _, rows in ipairs(row_lists) do
        for _, row in ipairs(rows) do
            local id = (row.kind or "?") .. "\0" .. row.key
            local existing = by_key[id]
            if existing == nil then
                by_key[id] = {
                    kind = row.kind or "?",
                    key = row.key,
                    count = row.count or 0,
                    last = row.last or 0,
                    desc = row.desc,
                }
            else
                existing.count = existing.count + (row.count or 0)
                existing.last = math.max(existing.last, row.last or 0)
                existing.desc = existing.desc or row.desc
            end
        end
    end
    return vim.tbl_values(by_key)
end

--- Drop stored events and summary rows whose key the denylist now matches.
---
--- Only ever removes. An event denied at capture time was never written, so dropping a
--- pattern from the denylist cannot bring its history back.
---@return table {events_removed, rows_removed}
function M.apply_denylist(dir, denylist)
    local removed = { events_removed = 0, rows_removed = 0 }
    if #(denylist or {}) == 0 then return removed end

    for _, path in ipairs(M.raw_files(dir)) do
        local kept = {}
        local events = read_lines(path)
        for _, event in ipairs(events) do
            if patterns.match_any(denylist, event.key) == nil then
                kept[#kept + 1] = event
            else
                removed.events_removed = removed.events_removed + 1
            end
        end
        if #kept < #events then
            local fh = assert(io.open(path, "w"))
            for _, event in ipairs(kept) do
                fh:write(vim.json.encode(event), "\n")
            end
            fh:close()
        end
    end

    for _, path in ipairs(M.summary_files(dir)) do
        local summary = read_json(path)
        if summary ~= nil and type(summary.rows) == "table" then
            local kept = {}
            for _, row in ipairs(summary.rows) do
                if patterns.match_any(denylist, row.key) == nil then
                    kept[#kept + 1] = row
                else
                    removed.rows_removed = removed.rows_removed + 1
                end
            end
            if #kept < #summary.rows then
                summary.rows = kept
                write_json(path, summary)
            end
        end
    end

    return removed
end

--- Denylist last applied to this host's stored data, for detecting a config change.
function M.read_applied_denylist(dir, host)
    local meta = read_json(M.meta_path(dir, host))
    if meta == nil or type(meta.denylist) ~= "table" then return nil end
    return meta.denylist
end

function M.write_applied_denylist(dir, host, denylist)
    write_json(M.meta_path(dir, host), { denylist = denylist or {}, applied_at = os.time() })
end

return M
