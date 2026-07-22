-- Buffered JSONL event writer. Events accumulate in memory and flush in batches so
-- that recording a keystroke never costs a disk write.
--
-- Flushing is synchronous on purpose. The batch is small (a few dozen short lines)
-- and VimLeavePre has to flush before the process exits, where an async write is not
-- guaranteed to complete.

local M = {}

local MAX_BUFFERED = 200

--- Create a writer appending JSONL to the path `path_for(event)` returns.
--- Batches are grouped by target path, so a flush spanning a month boundary lands each
--- event in the file for its own month.
--- Returns nil when the directory cannot be created, which the caller should treat as
--- "tracking is off on this machine" rather than an error.
--- Do not reuse the returned table after calling close().
---@param cfg table {dir, path_for, flush_interval_ms}
---@return table|nil
function M.new(cfg)
    if vim.fn.isdirectory(cfg.dir) == 0 then
        local ok = pcall(vim.fn.mkdir, cfg.dir, "p")
        if not ok or vim.fn.isdirectory(cfg.dir) == 0 then return nil end
    end

    local buffered = {}

    local function flush()
        if #buffered == 0 then return end

        local by_path = {}
        for _, event in ipairs(buffered) do
            local path = cfg.path_for(event)
            by_path[path] = by_path[path] or {}
            table.insert(by_path[path], event)
        end
        -- Clear first: a batch that cannot be written is dropped rather than retried
        -- forever, so an unmounted sync volume cannot grow the buffer without bound.
        buffered = {}

        for path, events in pairs(by_path) do
            local fh = io.open(path, "a")
            if fh ~= nil then
                for _, event in ipairs(events) do
                    fh:write(vim.json.encode(event), "\n")
                end
                fh:close()
            end
        end
    end

    local function add(event)
        buffered[#buffered + 1] = event
        if #buffered >= MAX_BUFFERED then flush() end
    end

    local timer
    if (cfg.flush_interval_ms or 0) > 0 then
        timer = vim.uv.new_timer()
        timer:start(cfg.flush_interval_ms, cfg.flush_interval_ms, vim.schedule_wrap(flush))
    end

    local function close()
        if timer ~= nil then
            timer:stop()
            timer:close()
            timer = nil
        end
        flush()
    end

    return { add = add, flush = flush, close = close }
end

return M
