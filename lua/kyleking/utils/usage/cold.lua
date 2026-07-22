-- The cold view: everything registered but never (or barely) triggered, ranked coldest
-- first. Remove-or-practice is one decision made per row, so under-used and never-used
-- share a list; the count and last-used date tell "never knew it existed" apart from
-- "tried it once and dropped it".
--
-- Reconciliation runs here, at report time, rather than at startup: deferred plugin
-- loading means the full keymap set only exists after startup drains, so a live
-- snapshot when the report opens is both simpler and always current.
--
-- Key normalization is the whole correctness problem. nvim_get_keymap hands back the
-- leader already expanded (" ff") while the log stores the lhs as it was passed to
-- vim.keymap.set ("<leader>ff"). Both sides go through nvim_replace_termcodes, which
-- expands <leader>/<localleader> and folds case variants (<C-I> and <C-i> are one key),
-- so the two forms meet at the same byte string.

local patterns = require("kyleking.utils.usage.patterns")
local report = require("kyleking.utils.usage.report")

local M = {}

local DEFAULT_LIMIT = 40

-- "v" overlaps "x"/"s" and is listed anyway so a visual-only map is not missed; the
-- dedup pass collapses the repeats.
local MODES = { "n", "x", "o", "i", "v", "s", "t", "c" }

--- Canonical byte form of a key, shared by both sides of the reconciliation.
M.normalize = patterns.normalize

-- Plugin-internal mappings are not things I type, so they can never be "cold". <Plug>
-- and <SNR> entries exist only as targets for other maps.
local function is_internal(lhs) return lhs:find("<Plug>", 1, true) ~= nil or lhs:find("<SNR>", 1, true) ~= nil end

local function add(rows, seen, row)
    if row.key == "" or is_internal(row.key) then return end
    local id = row.kind .. "\0" .. M.normalize(row.key)
    local existing = seen[id]
    if existing == nil then
        seen[id] = row
        rows[#rows + 1] = row
        return
    end
    existing.desc = existing.desc or row.desc
end

local function collect_keymaps(rows, seen)
    local buffers = vim.tbl_filter(function(buf) return vim.bo[buf].buflisted end, vim.api.nvim_list_bufs())

    for _, mode in ipairs(MODES) do
        for _, km in ipairs(vim.api.nvim_get_keymap(mode)) do
            add(rows, seen, { kind = "map", key = km.lhs or "", desc = km.desc, mode = mode })
        end
        for _, buf in ipairs(buffers) do
            local ok, buf_maps = pcall(vim.api.nvim_buf_get_keymap, buf, mode)
            for _, km in ipairs(ok and buf_maps or {}) do
                add(rows, seen, { kind = "map", key = km.lhs or "", desc = km.desc, mode = mode })
            end
        end
    end
end

local function collect_commands(rows, seen)
    for name, def in pairs(vim.api.nvim_get_commands({ builtin = false })) do
        add(rows, seen, { kind = "cmd", key = name, desc = def.definition })
    end
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        local ok, cmds = pcall(vim.api.nvim_buf_get_commands, buf, {})
        for name, def in pairs(ok and cmds or {}) do
            add(rows, seen, { kind = "cmd", key = name, desc = def.definition })
        end
    end
end

--- Every currently-registered keymap and user command, deduplicated by kind and key.
---@return table[] rows {kind, key, desc, mode}
function M.registered()
    local rows, seen = {}, {}
    collect_keymaps(rows, seen)
    collect_commands(rows, seen)
    return rows
end

--- Usage from the log, keyed by kind and normalized key.
local function usage_index(dir)
    local index = {}
    for _, row in ipairs(report.aggregate(dir)) do
        local id = (row.kind or "?") .. "\0" .. M.normalize(row.key)
        local existing = index[id]
        if existing == nil then
            index[id] = { count = row.count or 0, last = row.last or 0, desc = row.desc }
        else
            existing.count = existing.count + (row.count or 0)
            existing.last = math.max(existing.last, row.last or 0)
            existing.desc = existing.desc or row.desc
        end
    end
    return index
end

--- Denied keys are noise by definition, so they are omitted rather than shown as cold.
--- The denylist is written in logged form ("<Space>") while a registered lhs arrives
--- expanded (" "), so patterns are matched against both forms. Normalizing the denylist
--- is hoisted to the caller: it is loop-invariant across several hundred registered rows.
local function is_denied(denylist, normalized_denylist, key)
    if patterns.match_any(denylist, key) ~= nil then return true end
    return patterns.match_any(normalized_denylist, M.normalize(key)) ~= nil
end

--- Reconcile registered maps and commands against the aggregated log.
--- count 0 and last 0 mean the item was never triggered.
---@param dir string
---@return table[] rows {kind, key, desc, count, last} coldest first
function M.cold(dir)
    local denylist = patterns.load(dir).denylist
    local normalized_denylist = vim.tbl_map(M.normalize, denylist)
    local used = usage_index(dir)
    local rows = {}

    for _, item in ipairs(M.registered()) do
        if not is_denied(denylist, normalized_denylist, item.key) then
            local hit = used[item.kind .. "\0" .. M.normalize(item.key)] or { count = 0, last = 0 }
            rows[#rows + 1] = {
                kind = item.kind,
                key = item.key,
                desc = item.desc or hit.desc,
                mode = item.mode,
                count = hit.count,
                last = hit.last,
            }
        end
    end

    table.sort(rows, function(a, b)
        if a.count ~= b.count then return a.count < b.count end
        if a.last ~= b.last then return a.last < b.last end
        return a.key < b.key
    end)
    return rows
end

---@param rows table[]
---@param limit number|nil
---@return string[]
function M.render(rows, limit)
    limit = limit or DEFAULT_LIMIT
    if #rows == 0 then return { "Nothing registered to reconcile." } end

    local never = 0
    for _, row in ipairs(rows) do
        if row.count == 0 then never = never + 1 end
    end

    local lines = {
        ("Cold features: %d of %d registered never used, showing %d"):format(never, #rows, math.min(limit, #rows)),
        "",
    }
    for i = 1, math.min(limit, #rows) do
        local row = rows[i]
        local last = row.count > 0 and row.last > 0 and os.date("%Y-%m-%d", row.last) or "never"
        lines[#lines + 1] = ("%6d  %-4s %-24s %-12s %s"):format(row.count, row.kind, row.key, last, row.desc or "")
    end
    return lines
end

--- Open the cold view in a scratch buffer.
function M.show(dir)
    local lines = M.render(M.cold(dir))
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.bo[buf].modifiable = false
    vim.bo[buf].bufhidden = "wipe"
    vim.api.nvim_win_set_buf(0, buf)
end

return M
