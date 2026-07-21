-- Thin compatibility layer over Neovim's built-in vim.pack, exposing the small
-- slice of the mini.deps API the config relies on: add(), now(), later().
--
-- Deferred loading (later) mirrors mini.deps: queued callbacks run one per event
-- loop tick after startup so the UI stays responsive. Plugin install/update/version
-- state is tracked by vim.pack's own lockfile (nvim-pack-lock.json).

local M = {}

local function notify_error(context, err)
    vim.schedule(function() vim.notify(("pack %s error: %s"):format(context, err), vim.log.levels.ERROR) end)
end

local function safe_call(context, f)
    local ok, err = pcall(f)
    if not ok then notify_error(context, tostring(err)) end
end

--- Run a function immediately (fail-safe).
function M.now(f) safe_call("now", f) end

local later_queue = {}
local later_active = false

local function process_next()
    local f = table.remove(later_queue, 1)
    if f == nil then
        later_active = false
        return
    end
    safe_call("later", f)
    vim.schedule(process_next)
end

--- Queue a function to run after startup, one per event loop tick.
function M.later(f)
    later_queue[#later_queue + 1] = f
    if not later_active then
        later_active = true
        vim.schedule(process_next)
    end
end

local function to_url(source)
    if source:match("^%w[%w+.-]*://") then return source end
    return "https://github.com/" .. source
end

local function spec_name(url) return (vim.fn.fnamemodify(url, ":t"):gsub("%.git$", "")) end

-- Names added during this session. Deduping against this (not vim.pack.get(), which
-- reports every lockfile-installed plugin) lets a `depends` on an already-added plugin
-- like mini.nvim be skipped without suppressing the real add of a not-yet-loaded plugin.
local added_names = {}

--- Install (if needed) and load a plugin, mirroring MiniDeps.add.
--- Accepts a "author/name" or URL string, or a table:
---   { source = <str>, name = <str>, checkout = <version>, depends = {<str|table>...},
---     hooks = { post_checkout = <fn> } }
function M.add(spec)
    if type(spec) == "string" then spec = { source = spec } end

    local pack_specs = {}
    local function queue(pack_spec)
        local name = pack_spec.name or spec_name(pack_spec.src)
        if added_names[name] then return end
        added_names[name] = true
        pack_specs[#pack_specs + 1] = pack_spec
    end

    for _, dep in ipairs(spec.depends or {}) do
        local dep_src = type(dep) == "string" and dep or dep.source
        queue({ src = to_url(dep_src) })
    end

    local main = { src = to_url(spec.source) }
    if spec.name then main.name = spec.name end
    if spec.checkout then main.version = spec.checkout end
    queue(main)

    if #pack_specs > 0 then vim.pack.add(pack_specs, { confirm = false, load = true }) end

    if spec.hooks and spec.hooks.post_checkout then
        local name = main.name or spec_name(main.src)
        vim.api.nvim_create_autocmd("PackChanged", {
            callback = function(ev)
                local data = ev.data
                if data.spec.name == name and (data.kind == "install" or data.kind == "update") then
                    vim.schedule(function() safe_call("post_checkout", spec.hooks.post_checkout) end)
                end
            end,
        })
    end
end

--- List plugins vim.pack knows about (installed on disk / in the lockfile) that were
--- NOT added via M.add() in the current session, e.g. leftover from a removed add()
--- call. Only accurate once all `later()` callbacks have run -- if a `later()` add()
--- hasn't fired yet, its plugin looks orphaned even though it's still wanted. Some
--- deps files also add() conditionally (e.g. skipped when headless, or behind a
--- tool-detection check), so treat the result as review candidates, not a delete list.
function M.list_orphans()
    local orphans = {}
    for _, p in ipairs(vim.pack.get()) do
        if not p.active then orphans[#orphans + 1] = p.spec.name end
    end
    table.sort(orphans)
    return orphans
end

--- Remove the given plugin names (per M.list_orphans) from disk and the lockfile.
function M.clean(names)
    if #names == 0 then
        vim.notify("pack clean: no orphaned plugins", vim.log.levels.INFO)
        return
    end
    vim.pack.del(names)
end

-- Report-only by default (:PackClean); requires the bang (:PackClean!) to actually
-- delete, since orphan detection is a heuristic, not a guarantee -- see M.list_orphans.
vim.api.nvim_create_user_command("PackClean", function(cmd_opts)
    if #vim.api.nvim_list_uis() == 0 then
        vim.notify(
            "pack clean: skipped, no UI attached (some plugins are only added() when a UI is present)",
            vim.log.levels.WARN
        )
        return
    end
    if later_active or #later_queue > 0 then
        vim.notify("pack clean: still loading deferred plugins, try again in a moment", vim.log.levels.WARN)
        return
    end

    local orphans = M.list_orphans()
    if #orphans == 0 then
        vim.notify("pack clean: no orphaned plugins", vim.log.levels.INFO)
        return
    end
    if not cmd_opts.bang then
        vim.notify(
            "pack clean: not added this session: "
                .. table.concat(orphans, ", ")
                .. ". Verify each is truly unused (some deps files add() conditionally), then :PackClean! to delete.",
            vim.log.levels.WARN
        )
        return
    end
    M.clean(orphans)
end, { bang = true, desc = "List (or, with !, delete) plugins installed but not added this session" })

return M
