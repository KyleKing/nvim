-- Motion sampling: rebuild compound motions ("ciw", "di(", "gUiw") out of the raw key
-- stream, so the report counts semantic units instead of individual keypresses.
--
-- The assembler is pure. It takes keys and mode strings and calls back with finished
-- sequences; every editor hook (vim.on_key, ModeChanged, the idle timer) lives in
-- attach(). That split is what makes the heuristic testable without real keystrokes.
--
-- Filtering is not done here. The caller runs each sequence through patterns.lua, so
-- this module only decides where one sequence ends and the next begins.
--
-- Known misattribution, accepted up front (a directional signal, not an exact ledger):
--   * a count prefix breaks off as its own sequence: "3ciw" logs "3" then "ciw"
--   * a register prefix stays attached, so '"ayy' logs as one four-key sequence
--   * a remapped operator logs the keys typed, not the operation that ran
--   * a visual-mode text object ("viw") changes no mode, so it only resolves on the
--     idle timeout and can absorb whatever is typed next inside the timeout

local M = {}

local DEFAULT_MAX_SEQ_LEN = 6
local DEFAULT_IDLE_MS = 400

-- Keys that swallow the next key as an argument, or open a multi-key namespace. Neither
-- kind leaves normal mode while it waits, so without this the assembler would cut "f;"
-- and "gUiw" apart at the first key.
local CONTINUES = {}
for key in ("fFtTrmqgzZ'`\"@[]"):gmatch(".") do
    CONTINUES[key] = true
end

local VISUAL = { v = true, V = true, ["\22"] = true }

--- Normal (including operator-pending and terminal-normal) or visual. Insert, replace,
--- select, cmdline, and terminal keys are not motions and are skipped.
local function is_sampled(mode)
    local first = mode:sub(1, 1)
    return first == "n" or VISUAL[first] == true
end

--- A rest state is normal mode with nothing in flight. Visual is deliberately not rest:
--- "viw" never leaves visual, so treating it as rest would split it into three rows.
local function default_is_rest(mode) return mode:sub(1, 1) == "n" and mode:sub(2, 2) ~= "o" end

--- True while an operation is still being typed, so a mode change into it must not flush.
local function holds_operation(mode)
    local first = mode:sub(1, 1)
    return VISUAL[first] == true or (first == "n" and mode:sub(2, 2) == "o")
end

--- Sequence assembler. Feed it keys with the mode observed *before* each key is
--- processed (what vim.on_key sees); it calls `on_sequence` once per assembled motion.
--- Holds no editor state: no autocmds, no on_key, no globals.
---@param opts table|nil {on_sequence, max_seq_len, is_rest}
---@return table {feed, flush, pending}
function M.new_assembler(opts)
    opts = opts or {}
    local on_sequence = opts.on_sequence or function() end
    local max_seq_len = opts.max_seq_len or DEFAULT_MAX_SEQ_LEN
    local is_rest = opts.is_rest or default_is_rest

    -- `buf` is reused across sequences and only read up to `count`, so a sequence
    -- costs one array store per key and one concat per emit.
    local buf, count, overflow, held = {}, 0, false, false

    local function reset()
        count, overflow, held = 0, false, false
    end

    local function flush()
        if count > 0 and not overflow then on_sequence(table.concat(buf, "", 1, count)) end
        reset()
    end

    --- Append `key`, first emitting whatever came before it if that operation resolved.
    --- A key may be several characters when a mapping resolved as a unit ("iw").
    local function feed(key, mode)
        if not is_sampled(mode) then
            flush()
            return
        end
        if count > 0 and not held and is_rest(mode) then flush() end
        held = CONTINUES[key] == true

        count = count + 1
        if count > max_seq_len then
            -- Past the cap the whole sequence is discarded rather than truncated, so a
            -- stuck buffer logs nothing instead of logging a plausible-looking prefix.
            overflow = true
            return
        end
        buf[count] = key
    end

    --- Keys accumulated but not yet emitted. Empty once a sequence has overflowed.
    local function pending()
        if overflow or count == 0 then return "" end
        return table.concat(buf, "", 1, count)
    end

    return { feed = feed, flush = flush, pending = pending }
end

local AUGROUP = "kyleking_usage_motion"

-- Skip the vimscript call for the common all-printable sequence.
local function readable(seq)
    if seq:find("[%z\1-\31\128-\255]") == nil then return seq end
    local ok, pretty = pcall(vim.fn.keytrans, seq)
    return ok and pretty or seq
end

--- Attach the assembler to the editor. Returns a handle whose stop() fully detaches.
--- `on_sequence` receives a printable sequence ("ciw", "<Esc>"), unfiltered.
---@param opts table {on_sequence, max_seq_len, idle_ms, is_rest}
---@return table {stop, assembler}
function M.attach(opts)
    opts = opts or {}
    local idle_ms = opts.idle_ms or DEFAULT_IDLE_MS
    local emit = opts.on_sequence or function() end

    local assembler = M.new_assembler({
        max_seq_len = opts.max_seq_len,
        is_rest = opts.is_rest,
        on_sequence = function(seq) emit(readable(seq)) end,
    })

    local dirty, settled = false, false

    local ns = vim.api.nvim_create_namespace(AUGROUP)
    vim.on_key(function(_key, typed)
        -- `typed` is what was pressed, `_key` what it resolved to, and only `typed` is
        -- usable: keys a mapping or feedkeys replays arrive with `typed` empty, so this
        -- both skips the replay (already counted by the keymap hook) and keeps a mapped
        -- text object whole, since mini.ai's `iw` arrives once as typed="iw".
        if typed == nil or typed == "" then return end
        dirty, settled = true, false
        -- Queried per key rather than cached off ModeChanged: 0.1us, and a cache goes
        -- silently wrong wherever ModeChanged is suppressed (`eventignore`, `noautocmd`),
        -- which turns every compound motion into single keys.
        assembler.feed(typed, vim.api.nvim_get_mode().mode)
    end, ns)

    -- Only an optimization: it emits "ciw" the moment insert starts instead of waiting
    -- for the idle tick. Nothing breaks if these events never arrive.
    local group = vim.api.nvim_create_augroup(AUGROUP, { clear = true })
    vim.api.nvim_create_autocmd("ModeChanged", {
        group = group,
        pattern = "*:*",
        callback = function()
            local new_mode = vim.v.event.new_mode
            if new_mode ~= nil and not holds_operation(new_mode) then assembler.flush() end
        end,
    })

    -- A repeating tick with a two-tick grace beats restarting a timer per key: the hot
    -- path stays two boolean stores, and an idle editor compares two booleans per tick.
    local timer = vim.uv.new_timer()
    timer:start(
        idle_ms,
        idle_ms,
        vim.schedule_wrap(function()
            if not dirty then return end
            if not settled then
                settled = true
                return
            end
            dirty, settled = false, false
            assembler.flush()
        end)
    )

    local function stop()
        vim.on_key(nil, ns)
        if timer ~= nil and not timer:is_closing() then
            timer:stop()
            timer:close()
        end
        timer = nil
        pcall(vim.api.nvim_del_augroup_by_name, AUGROUP)
    end

    return { stop = stop, assembler = assembler }
end

return M
