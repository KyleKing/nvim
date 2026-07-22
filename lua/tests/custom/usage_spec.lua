local MiniTest = require("mini.test")
local helpers = require("tests.helpers")
local usage = require("kyleking.utils.usage")
local writer = require("kyleking.utils.usage.writer")
local report = require("kyleking.utils.usage.report")

local tmp_dirs = {}

local function make_dir()
    local dir = vim.fn.tempname()
    tmp_dirs[#tmp_dirs + 1] = dir
    return dir
end

local function read_events(path)
    local events = {}
    if vim.fn.filereadable(path) == 0 then return events end
    for line in io.lines(path) do
        events[#events + 1] = vim.json.decode(line)
    end
    return events
end

-- flush_interval_ms = 0 disables the timer so every test flushes explicitly.
local function install(dir)
    return usage.install({ dir = dir, host = "testhost", enabled = true, flush_interval_ms = 0 })
end

local T = MiniTest.new_set({
    hooks = {
        post_case = function()
            usage.uninstall()
            for _, dir in ipairs(tmp_dirs) do
                vim.fn.delete(dir, "rf")
            end
            tmp_dirs = {}
        end,
    },
})

T["writer"] = MiniTest.new_set()

T["writer"]["writes one JSON object per line"] = function()
    local w = writer.new({ dir = make_dir(), host = "h", flush_interval_ms = 0 })
    w.add({ kind = "map", key = "a" })
    w.add({ kind = "cmd", key = "w" })
    w.flush()

    local events = read_events(w.path)
    MiniTest.expect.equality(#events, 2)
    MiniTest.expect.equality(events[1].key, "a")
    MiniTest.expect.equality(events[2].kind, "cmd")
end

T["writer"]["buffers until flushed"] = function()
    local w = writer.new({ dir = make_dir(), host = "h", flush_interval_ms = 0 })
    w.add({ kind = "map", key = "a" })
    MiniTest.expect.equality(#read_events(w.path), 0, "should not touch disk before flush")
    w.flush()
    MiniTest.expect.equality(#read_events(w.path), 1)
end

T["writer"]["flushing nothing is a no-op"] = function()
    local w = writer.new({ dir = make_dir(), host = "h", flush_interval_ms = 0 })
    w.flush()
    w.flush()
    MiniTest.expect.equality(#read_events(w.path), 0)
end

T["writer"]["appends across flushes"] = function()
    local w = writer.new({ dir = make_dir(), host = "h", flush_interval_ms = 0 })
    w.add({ kind = "map", key = "a" })
    w.flush()
    w.add({ kind = "map", key = "b" })
    w.flush()
    MiniTest.expect.equality(#read_events(w.path), 2, "second flush must not truncate the first")
end

T["command_name"] = MiniTest.new_set()

T["command_name"]["reads plain and user commands"] = function()
    MiniTest.expect.equality(usage.command_name("w"), "w")
    MiniTest.expect.equality(usage.command_name("PackClean"), "PackClean")
    MiniTest.expect.equality(usage.command_name("  RunAllTests"), "RunAllTests")
end

T["command_name"]["skips range prefixes"] = function()
    MiniTest.expect.equality(usage.command_name("%s/foo/bar"), "s")
    MiniTest.expect.equality(usage.command_name("'<,'>sort"), "sort")
    MiniTest.expect.equality(usage.command_name("1,5d"), "d")
end

T["command_name"]["ignores a bare line jump"] = function()
    MiniTest.expect.equality(usage.command_name("42"), nil)
    MiniTest.expect.equality(usage.command_name(""), nil)
end

T["install"] = MiniTest.new_set()

T["install"]["stays off without an explicit dir when root is missing"] = function()
    local installed = usage.install({ root = "/nonexistent-sync-root", enabled = true })
    MiniTest.expect.equality(installed, false, "an unsynced machine should not be tracked")
end

T["install"]["is off by default in headless"] = function()
    MiniTest.expect.equality(usage.install({ dir = make_dir() }), false)
end

T["maps"] = MiniTest.new_set()

-- Invoke through the registered callback rather than feedkeys. Per AGENTS.md, <leader>
-- maps are driven by API call in tests: key resolution depends on global state other
-- specs mutate (clue prefixes, pending operators), which is nvim's behavior to get
-- right, not this wrapper's. End-to-end resolution is covered by driving the real
-- config in a subprocess instead.
local function invoke(lhs)
    local _, keymap = helpers.check_keymap(lhs, "n")
    assert(keymap ~= nil and keymap.callback ~= nil, "expected a callback keymap at " .. lhs)
    return keymap.callback()
end

local function map_events(dir)
    return vim.tbl_filter(function(event) return event.kind == "map" end, read_events(dir .. "/testhost.jsonl"))
end

T["maps"]["records an invocation with its desc"] = function()
    local dir = make_dir()
    MiniTest.expect.equality(install(dir), true)

    local called = 0
    vim.keymap.set("n", "<leader>zz", function() called = called + 1 end, { desc = "Test map" })
    invoke("<leader>zz")
    usage.flush()

    MiniTest.expect.equality(called, 1, "original callback must still run")
    local events = map_events(dir)
    MiniTest.expect.equality(#events, 1)
    MiniTest.expect.equality(events[1].key, "<leader>zz")
    MiniTest.expect.equality(events[1].desc, "Test map")

    vim.keymap.del("n", "<leader>zz")
end

T["maps"]["preserves the return value of an expr map"] = function()
    install(make_dir())

    vim.keymap.set("n", "<leader>ze", function() return "ihello" end, { expr = true })
    MiniTest.expect.equality(invoke("<leader>ze"), "ihello", "expr maps depend on the rhs return value")

    vim.keymap.del("n", "<leader>ze")
end

T["maps"]["records even when the callback errors"] = function()
    local dir = make_dir()
    install(dir)

    vim.keymap.set("n", "<leader>zx", function() error("boom") end, { desc = "Explodes" })
    local ok = pcall(invoke, "<leader>zx")
    usage.flush()

    MiniTest.expect.equality(ok, false, "the error must still propagate")
    local events = map_events(dir)
    MiniTest.expect.equality(#events, 1, "a failing map still counts as used")
    MiniTest.expect.equality(events[1].key, "<leader>zx")

    vim.keymap.del("n", "<leader>zx")
end

T["maps"]["leaves a string rhs untouched"] = function()
    install(make_dir())

    vim.keymap.set("n", "<leader>zs", "ihi<Esc>")
    local _, keymap = helpers.check_keymap("<leader>zs", "n")
    MiniTest.expect.equality(keymap.callback, nil, "a string rhs has no callback to wrap")
    MiniTest.expect.equality(keymap.rhs, "ihi<Esc>", "the string rhs must pass through unchanged")

    vim.keymap.del("n", "<leader>zs")
end

T["maps"]["restores the original setter on uninstall"] = function()
    local before = vim.keymap.set
    install(make_dir())
    MiniTest.expect.equality(vim.keymap.set ~= before, true, "should be patched while installed")
    usage.uninstall()
    MiniTest.expect.equality(vim.keymap.set, before)
end

T["report"] = MiniTest.new_set()

local function write_host(dir, host, events)
    vim.fn.mkdir(dir, "p")
    local fh = assert(io.open(dir .. "/" .. host .. ".jsonl", "w"))
    for _, event in ipairs(events) do
        fh:write(vim.json.encode(event), "\n")
    end
    fh:close()
end

T["report"]["unions hosts and ranks by count"] = function()
    local dir = make_dir()
    write_host(dir, "mbp", {
        { kind = "map", key = "<leader>ff", desc = "Find files", ts = 100 },
        { kind = "map", key = "<leader>ff", ts = 200 },
        { kind = "cmd", key = "w", ts = 150 },
    })
    write_host(dir, "desktop", {
        { kind = "map", key = "<leader>ff", ts = 300 },
        { kind = "cmd", key = "w", ts = 120 },
    })

    local rows = report.aggregate(dir)
    MiniTest.expect.equality(#rows, 2)
    MiniTest.expect.equality(rows[1].key, "<leader>ff")
    MiniTest.expect.equality(rows[1].count, 3, "counts must sum across host files")
    MiniTest.expect.equality(rows[1].desc, "Find files", "desc carries over from the event that had one")
    MiniTest.expect.equality(rows[1].last, 300, "last-used is the newest across hosts")
    MiniTest.expect.equality(rows[2].count, 2)
end

T["report"]["skips malformed lines"] = function()
    local dir = make_dir()
    vim.fn.mkdir(dir, "p")
    local fh = assert(io.open(dir .. "/h.jsonl", "w"))
    fh:write('{"kind":"map","key":"a","ts":1}\n')
    fh:write("{not json at all\n")
    fh:write('{"kind":"map","key":"a","ts":2}\n')
    fh:close()

    local rows = report.aggregate(dir)
    MiniTest.expect.equality(#rows, 1)
    MiniTest.expect.equality(rows[1].count, 2, "a torn line must not lose the valid ones")
end

T["report"]["handles an empty directory"] = function()
    local rows = report.aggregate(make_dir())
    MiniTest.expect.equality(#rows, 0)
    MiniTest.expect.equality(report.render(rows), { "No usage recorded yet." })
end

if MiniTest.current.all_cases == nil then MiniTest.run() end

return T
