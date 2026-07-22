-- Buffered JSONL event writer. Events accumulate in memory and flush in batches so
-- that recording a keystroke never costs a disk write.
--
-- Flushing is synchronous on purpose. The batch is small (a few dozen short lines)
-- and VimLeavePre has to flush before the process exits, where an async write is not
-- guaranteed to complete.

local M = {}

local MAX_BUFFERED = 200

--- Create a writer appending JSONL to `dir/<host>.jsonl`.
--- Returns nil when the directory cannot be created, which the caller should treat as
--- "tracking is off on this machine" rather than an error.
--- Do not reuse the returned table after calling close().
---@param cfg table {dir, host, flush_interval_ms}
---@return table|nil
function M.new(cfg)
    if vim.fn.isdirectory(cfg.dir) == 0 then
        local ok = pcall(vim.fn.mkdir, cfg.dir, "p")
        if not ok or vim.fn.isdirectory(cfg.dir) == 0 then return nil end
    end

    local path = cfg.dir .. "/" .. cfg.host .. ".jsonl"
    local buffered = {}

    local function flush()
        if #buffered == 0 then return end
        local fh = io.open(path, "a")
        -- Drop the batch rather than growing it without bound when the sync folder
        -- goes away mid-session (unmounted volume, revoked permissions).
        if fh == nil then
            buffered = {}
            return
        end
        for _, event in ipairs(buffered) do
            fh:write(vim.json.encode(event), "\n")
        end
        fh:close()
        buffered = {}
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

    return { add = add, flush = flush, close = close, path = path }
end

return M
