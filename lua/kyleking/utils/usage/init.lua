-- Feature-usage tracking: which keymaps and commands I actually use, so cold ones can
-- be removed or deliberately practiced. See FEATURE_USAGE_DESIGN.md.
--
-- install() must run before lua/kyleking/core is required, because core/keymaps.lua and
-- every deps/*.lua file capture `local K = vim.keymap.set` at require-time. Patching
-- after that point leaves those aliases pointing at the unwrapped function.

local patterns = require("kyleking.utils.usage.patterns")
local store = require("kyleking.utils.usage.store")
local writer = require("kyleking.utils.usage.writer")

local M = {}

local state = {
    installed = false,
    writer = nil,
    cfg = nil,
    original_set = nil,
    patterns = { denylist = {}, groups = {} },
}

local function sanitize_host(host) return (host:gsub("[^%w%-_.]", "_")) end

local function build_cfg(opts)
    local cfg = vim.tbl_deep_extend("force", {
        root = vim.fn.expand("~/Sync"),
        dir = nil,
        host = nil,
        flush_interval_ms = 30000,
        retention_months = 1,
        track = { maps = true, commands = true },
        redact_cwd = true,
    }, opts or {})

    -- An explicit dir (tests, a machine that syncs elsewhere) skips the root check.
    -- Otherwise a missing root means this machine is not synced, so stay off rather
    -- than create a folder that looks synced but is not.
    cfg.explicit_dir = cfg.dir ~= nil

    -- Escape hatch for verifying the real boot ordering: a headless nvim has no UI, so
    -- tracking is off by default and the line-1 wrapping cannot otherwise be observed.
    local env_dir = vim.env.NVIM_USAGE_DIR
    if not cfg.explicit_dir and env_dir ~= nil and env_dir ~= "" then
        cfg.dir, cfg.explicit_dir = env_dir, true
        if cfg.enabled == nil then cfg.enabled = true end
    end

    cfg.dir = cfg.dir or (cfg.root .. "/.nvim/usage")
    cfg.host = sanitize_host(cfg.host or vim.uv.os_gethostname() or "unknown")
    if cfg.enabled == nil then cfg.enabled = #vim.api.nvim_list_uis() > 0 end
    return cfg
end

--- Extract the command name from a cmdline, skipping any range prefix.
--- "%s/a/b" -> "substitute", "'<,'>sort" -> "sort", ":42" -> nil (a jump, not a command).
---
--- Abbreviations are expanded so that :w, :wr, and :write count as one command rather
--- than three rows. Unknown names (a typo, a not-yet-loaded plugin command) fall back
--- to what was typed.
---@param line string
---@return string|nil
function M.command_name(line)
    local typed = line:match("^%s*[^%a]*(%a[%w_]*)")
    if typed == nil then return nil end
    local ok, full = pcall(vim.fn.fullcommand, typed)
    if ok and full ~= nil and full ~= "" then return full end
    return typed
end

local function project_name()
    local cwd = vim.uv.cwd() or ""
    if state.cfg.redact_cwd then return vim.fn.fnamemodify(cwd, ":t") end
    return cwd
end

-- `host` is deliberately absent from each event: the filename already carries it, and
-- repeating it cost about a quarter of every line.
local function record(kind, key, desc)
    if state.writer == nil then return end
    if patterns.match_any(state.patterns.denylist, key) ~= nil then return end
    local ft = vim.bo.filetype
    state.writer.add({
        ts = os.time(),
        kind = kind,
        key = key,
        desc = desc,
        mode = vim.fn.mode(),
        ft = ft ~= "" and ft or nil,
        cwd = project_name(),
    })
end

-- Records before calling so a keymap whose callback errors still counts as used.
-- Returns rhs's values untouched, which `expr = true` maps depend on.
local function wrap_rhs(lhs, rhs, desc)
    return function(...)
        record("map", lhs, desc)
        return rhs(...)
    end
end

local function patched_set(mode, lhs, rhs, opts)
    -- String and expr-string rhs have no callback to wrap, so they are registered
    -- unwrapped and stay invisible to invocation counts (documented blind spot).
    if type(rhs) == "function" then rhs = wrap_rhs(lhs, rhs, opts and opts.desc) end
    return state.original_set(mode, lhs, rhs, opts)
end

--- Start tracking. Returns true when tracking is active.
--- Off by default without a UI so tests, benchmarks, and headless runs write nothing.
---@param opts table|nil
---@return boolean
function M.install(opts)
    if state.installed then return false end

    local cfg = build_cfg(opts)
    if not cfg.enabled then return false end
    if not cfg.explicit_dir and vim.fn.isdirectory(cfg.root) == 0 then return false end

    local w = writer.new({
        dir = cfg.dir,
        flush_interval_ms = cfg.flush_interval_ms,
        path_for = function(event) return store.raw_path(cfg.dir, cfg.host, store.month_of(event.ts)) end,
    })
    if w == nil then return false end

    state.writer, state.cfg, state.installed = w, cfg, true

    -- Seed patterns.json on first run so the denylist is discoverable and hand-editable.
    -- <Space> is mini.clue's leader-prefix query map, which fires on every leader press
    -- and otherwise dominates the report.
    if vim.fn.filereadable(cfg.dir .. "/patterns.json") == 0 then
        patterns.save(cfg.dir, { denylist = { "<Space>" }, groups = {} })
    end
    state.patterns = patterns.load(cfg.dir)

    if cfg.track.maps then
        state.original_set = vim.keymap.set
        vim.keymap.set = patched_set
    end

    local group = vim.api.nvim_create_augroup("kyleking_usage", { clear = true })

    if cfg.track.commands then
        vim.api.nvim_create_autocmd("CmdlineLeave", {
            group = group,
            callback = function()
                if vim.v.event.abort then return end
                if vim.fn.getcmdtype() ~= ":" then return end
                local name = M.command_name(vim.fn.getcmdline())
                if name ~= nil then record("cmd", name) end
            end,
        })
    end

    vim.api.nvim_create_autocmd("VimLeavePre", { group = group, callback = function() M.flush() end })

    vim.api.nvim_create_user_command(
        "FeatureUsage",
        function() require("kyleking.utils.usage.report").show(cfg.dir) end,
        { desc = "Show keymap and command usage counts" }
    )

    vim.api.nvim_create_user_command(
        "FeatureUsageCompact",
        function() vim.notify(M.compact(), vim.log.levels.INFO) end,
        { desc = "Compact expired usage months and apply the current denylist to stored data" }
    )

    return true
end

--- Roll expired months into summaries and apply the current denylist to stored data.
--- Rewriting is explicit rather than automatic because it deletes events: an event
--- denied at capture time was never written, so removing a pattern from the denylist
--- cannot restore that history.
---@return string summary of what changed
function M.compact()
    if state.cfg == nil then return "usage tracking is not installed" end
    M.flush()

    local dir, host = state.cfg.dir, state.cfg.host
    local active = patterns.load(dir)
    local compacted = store.compact(dir, { retention_months = state.cfg.retention_months })
    local removed = store.apply_denylist(dir, active.denylist)
    store.write_applied_denylist(dir, host, active.denylist)
    state.patterns = active

    return ("usage: compacted %d month(s), removed %d event(s) and %d summary row(s)"):format(
        #compacted,
        removed.events_removed,
        removed.rows_removed
    )
end

--- True when patterns.json no longer matches what was last applied to stored data.
function M.denylist_drifted()
    if state.cfg == nil then return false end
    local applied = store.read_applied_denylist(state.cfg.dir, state.cfg.host)
    if applied == nil then return false end
    return not vim.deep_equal(applied, patterns.load(state.cfg.dir).denylist)
end

--- Write buffered events to disk now.
function M.flush()
    if state.writer ~= nil then state.writer.flush() end
end

--- Stop tracking and restore the original vim.keymap.set. Mainly for tests.
function M.uninstall()
    if not state.installed then return end
    if state.original_set ~= nil then vim.keymap.set = state.original_set end
    if state.writer ~= nil then state.writer.close() end
    pcall(vim.api.nvim_del_augroup_by_name, "kyleking_usage")
    pcall(vim.api.nvim_del_user_command, "FeatureUsage")
    pcall(vim.api.nvim_del_user_command, "FeatureUsageCompact")
    state = {
        installed = false,
        writer = nil,
        cfg = nil,
        original_set = nil,
        patterns = { denylist = {}, groups = {} },
    }
end

return M
