-- Feature-usage tracking: which keymaps and commands I actually use, so cold ones can
-- be removed or deliberately practiced. See FEATURE_USAGE_DESIGN.md.
--
-- install() must run before lua/kyleking/core is required, because core/keymaps.lua and
-- every deps/*.lua file capture `local K = vim.keymap.set` at require-time. Patching
-- after that point leaves those aliases pointing at the unwrapped function.

local writer = require("kyleking.utils.usage.writer")

local M = {}

local state = {
    installed = false,
    writer = nil,
    cfg = nil,
    original_set = nil,
}

local function sanitize_host(host) return (host:gsub("[^%w%-_.]", "_")) end

local function build_cfg(opts)
    local cfg = vim.tbl_deep_extend("force", {
        root = vim.fn.expand("~/Sync"),
        dir = nil,
        host = nil,
        flush_interval_ms = 30000,
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
--- "%s/a/b" -> "s", "'<,'>sort" -> "sort", ":42" -> nil (a jump, not a command).
---@param line string
---@return string|nil
function M.command_name(line) return line:match("^%s*[^%a]*(%a[%w_]*)") end

local function project_name()
    local cwd = vim.uv.cwd() or ""
    if state.cfg.redact_cwd then return vim.fn.fnamemodify(cwd, ":t") end
    return cwd
end

local function record(kind, key, desc)
    if state.writer == nil then return end
    local ft = vim.bo.filetype
    state.writer.add({
        ts = os.time(),
        kind = kind,
        key = key,
        desc = desc,
        mode = vim.fn.mode(),
        ft = ft ~= "" and ft or nil,
        cwd = project_name(),
        host = state.cfg.host,
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

    local w = writer.new({ dir = cfg.dir, host = cfg.host, flush_interval_ms = cfg.flush_interval_ms })
    if w == nil then return false end

    state.writer, state.cfg, state.installed = w, cfg, true

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

    return true
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
    state = { installed = false, writer = nil, cfg = nil, original_set = nil }
end

return M
