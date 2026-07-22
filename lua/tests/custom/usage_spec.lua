local MiniTest = require("mini.test")
local helpers = require("tests.helpers")
local patterns = require("kyleking.utils.usage.patterns")
local report = require("kyleking.utils.usage.report")
local store = require("kyleking.utils.usage.store")
local usage = require("kyleking.utils.usage")
local writer = require("kyleking.utils.usage.writer")

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

local function fixed_writer(dir)
    local path = dir .. "/h.jsonl"
    return assert(writer.new({ dir = dir, flush_interval_ms = 0, path_for = function() return path end })), path
end

T["writer"]["writes one JSON object per line"] = function()
    local w, path = fixed_writer(make_dir())
    w.add({ kind = "map", key = "a" })
    w.add({ kind = "cmd", key = "w" })
    w.flush()

    local events = read_events(path)
    MiniTest.expect.equality(#events, 2)
    MiniTest.expect.equality(events[1].key, "a")
    MiniTest.expect.equality(events[2].kind, "cmd")
end

T["writer"]["buffers until flushed"] = function()
    local w, path = fixed_writer(make_dir())
    w.add({ kind = "map", key = "a" })
    MiniTest.expect.equality(#read_events(path), 0, "should not touch disk before flush")
    w.flush()
    MiniTest.expect.equality(#read_events(path), 1)
end

T["writer"]["flushing nothing is a no-op"] = function()
    local w, path = fixed_writer(make_dir())
    w.flush()
    w.flush()
    MiniTest.expect.equality(#read_events(path), 0)
end

T["writer"]["appends across flushes"] = function()
    local w, path = fixed_writer(make_dir())
    w.add({ kind = "map", key = "a" })
    w.flush()
    w.add({ kind = "map", key = "b" })
    w.flush()
    MiniTest.expect.equality(#read_events(path), 2, "second flush must not truncate the first")
end

T["writer"]["splits one batch across month files"] = function()
    local dir = make_dir()
    local w = assert(writer.new({
        dir = dir,
        flush_interval_ms = 0,
        path_for = function(event) return ("%s/h-%s.jsonl"):format(dir, store.month_of(event.ts)) end,
    }))
    w.add({ kind = "map", key = "a", ts = os.time({ year = 2026, month = 6, day = 30, hour = 23 }) })
    w.add({ kind = "map", key = "b", ts = os.time({ year = 2026, month = 7, day = 1, hour = 1 }) })
    w.flush()

    MiniTest.expect.equality(#read_events(dir .. "/h-2026-06.jsonl"), 1, "June event lands in the June file")
    MiniTest.expect.equality(#read_events(dir .. "/h-2026-07.jsonl"), 1, "July event lands in the July file")
end

T["command_name"] = MiniTest.new_set()

T["command_name"]["reads plain and user commands"] = function()
    MiniTest.expect.equality(usage.command_name("write"), "write")
    MiniTest.expect.equality(usage.command_name("PackClean"), "PackClean")
end

T["command_name"]["collapses abbreviations onto one name"] = function()
    MiniTest.expect.equality(usage.command_name("w"), "write")
    MiniTest.expect.equality(usage.command_name("wr"), "write", ":w and :wr must not be separate rows")
    MiniTest.expect.equality(usage.command_name("noh"), "nohlsearch")
end

T["command_name"]["keeps an unknown name as typed"] = function()
    MiniTest.expect.equality(usage.command_name("NotARealCommandXyz"), "NotARealCommandXyz")
end

T["command_name"]["skips range prefixes"] = function()
    MiniTest.expect.equality(usage.command_name("%s/foo/bar"), "substitute")
    MiniTest.expect.equality(usage.command_name("'<,'>sort"), "sort")
    MiniTest.expect.equality(usage.command_name("1,5d"), "delete")
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
    local path = store.raw_path(dir, "testhost", store.month_of(os.time()))
    return vim.tbl_filter(function(event) return event.kind == "map" end, read_events(path))
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

T["patterns"] = MiniTest.new_set()

T["patterns"]["expands * across a family"] = function()
    MiniTest.expect.equality(patterns.matches("c*w", "ciw"), true)
    MiniTest.expect.equality(patterns.matches("c*w", "caw"), true)
    MiniTest.expect.equality(patterns.matches("c*w", "ciwx"), false, "must stay anchored at both ends")
    MiniTest.expect.equality(patterns.matches("c*w", "diw"), false)
end

T["patterns"]["treats magic characters literally"] = function()
    MiniTest.expect.equality(patterns.matches("di(", "di("), true)
    MiniTest.expect.equality(patterns.matches("di(", "diX"), false, "( must not act as a Lua capture")
    MiniTest.expect.equality(patterns.matches("$", "$"), true)
    MiniTest.expect.equality(patterns.matches("$", "x"), false, "$ must not act as an anchor")
    MiniTest.expect.equality(patterns.matches("%", "%"), true)
    MiniTest.expect.equality(patterns.matches(".", "x"), false, ". must not match any character")
end

T["patterns"]["is case-sensitive"] = function()
    MiniTest.expect.equality(patterns.matches("c*w", "ciW"), false, "ciW is a different motion from ciw")
    MiniTest.expect.equality(patterns.matches("c*W", "ciW"), true)
end

T["patterns"]["denies before grouping"] = function()
    local active = { denylist = { "ciw" }, groups = { "c*w" } }
    MiniTest.expect.equality(patterns.label(active, "ciw"), nil, "an explicit deny wins over a group")
    MiniTest.expect.equality(patterns.label(active, "caw"), "c*w", "other family members still collapse")
    MiniTest.expect.equality(patterns.label(active, "dd"), "dd", "unmatched keys keep their own name")
end

T["patterns"]["falls back when the file is malformed"] = function()
    local dir = make_dir()
    vim.fn.mkdir(dir, "p")
    local fh = assert(io.open(dir .. "/patterns.json", "w"))
    fh:write("{ not json")
    fh:close()

    local active = patterns.load(dir)
    MiniTest.expect.equality(active.denylist, {}, "a bad hand edit must not lose events")
end

T["store"] = MiniTest.new_set()

T["store"]["parses hostnames containing hyphens"] = function()
    local host, month = store.parse_raw_name("Kyles-MacBook-Pro.local-2026-07.jsonl")
    MiniTest.expect.equality(host, "Kyles-MacBook-Pro.local")
    MiniTest.expect.equality(month, "2026-07")
end

T["store"]["treats a pre-rotation file as legacy"] = function()
    local host, month = store.parse_raw_name("Kyles-MacBook-Pro.local.jsonl")
    MiniTest.expect.equality(host, "Kyles-MacBook-Pro.local")
    MiniTest.expect.equality(month, nil)
end

local function write_raw(dir, name, events)
    vim.fn.mkdir(dir, "p")
    local fh = assert(io.open(dir .. "/" .. name, "w"))
    for _, event in ipairs(events) do
        fh:write(vim.json.encode(event), "\n")
    end
    fh:close()
end

local JUNE = os.time({ year = 2026, month = 6, day = 15, hour = 12 })
local JULY = os.time({ year = 2026, month = 7, day = 15, hour = 12 })

T["store"]["compacts an expired month and keeps the current one"] = function()
    local dir = make_dir()
    write_raw(dir, "h-2026-06.jsonl", {
        { kind = "map", key = "a", ts = JUNE },
        { kind = "map", key = "a", ts = JUNE },
    })
    write_raw(dir, "h-2026-07.jsonl", { { kind = "map", key = "b", ts = JULY } })

    local compacted = store.compact(dir, { retention_months = 1, now = JULY })

    MiniTest.expect.equality(compacted, { "2026-06" })
    MiniTest.expect.equality(vim.fn.filereadable(dir .. "/h-2026-06.jsonl"), 0, "raw month is removed")
    MiniTest.expect.equality(vim.fn.filereadable(dir .. "/h-2026-07.jsonl"), 1, "current month is kept raw")

    local summary = assert(store.read_json(dir .. "/summary-h-2026-06.json"))
    MiniTest.expect.equality(#summary.rows, 1)
    MiniTest.expect.equality(summary.rows[1].count, 2, "counts survive compaction")
end

T["store"]["compaction preserves totals in the report"] = function()
    local dir = make_dir()
    write_raw(dir, "h-2026-06.jsonl", {
        { kind = "map", key = "a", ts = JUNE },
        { kind = "map", key = "a", ts = JUNE },
    })
    write_raw(dir, "h-2026-07.jsonl", { { kind = "map", key = "a", ts = JULY } })

    local before = report.aggregate(dir)
    store.compact(dir, { retention_months = 1, now = JULY })
    local after = report.aggregate(dir)

    MiniTest.expect.equality(before[1].count, 3)
    MiniTest.expect.equality(after[1].count, 3, "compaction must not change what the report shows")
    MiniTest.expect.equality(after[1].last, JULY)
end

T["store"]["dates a legacy file by its newest event"] = function()
    local dir = make_dir()
    write_raw(dir, "h.jsonl", { { kind = "map", key = "a", ts = JUNE } })

    store.compact(dir, { retention_months = 1, now = JULY })

    MiniTest.expect.equality(vim.fn.filereadable(dir .. "/h.jsonl"), 0, "pre-rotation file is compacted too")
    MiniTest.expect.equality(vim.fn.filereadable(dir .. "/summary-h-2026-06.json"), 1)
end

T["retro denylist"] = MiniTest.new_set()

T["retro denylist"]["removes matching events and summary rows"] = function()
    local dir = make_dir()
    write_raw(dir, "h-2026-07.jsonl", {
        { kind = "motion", key = "ciw", ts = JULY },
        { kind = "motion", key = "j", ts = JULY },
        { kind = "motion", key = "j", ts = JULY },
    })
    vim.fn.mkdir(dir, "p")
    local fh = assert(io.open(dir .. "/summary-h-2026-06.json", "w"))
    fh:write(vim.json.encode({
        host = "h",
        month = "2026-06",
        rows = {
            { kind = "motion", key = "j", count = 500, last = JUNE },
            { kind = "motion", key = "ciw", count = 9, last = JUNE },
        },
    }))
    fh:close()

    local removed = store.apply_denylist(dir, { "j" })

    MiniTest.expect.equality(removed.events_removed, 2)
    MiniTest.expect.equality(removed.rows_removed, 1)

    local rows = report.aggregate(dir)
    MiniTest.expect.equality(#rows, 1, "denied key is gone from both raw and summarized history")
    MiniTest.expect.equality(rows[1].key, "ciw")
end

T["retro denylist"]["leaves data alone when the denylist is empty"] = function()
    local dir = make_dir()
    write_raw(dir, "h-2026-07.jsonl", { { kind = "map", key = "a", ts = JULY } })

    local removed = store.apply_denylist(dir, {})

    MiniTest.expect.equality(removed.events_removed, 0)
    MiniTest.expect.equality(#read_events(dir .. "/h-2026-07.jsonl"), 1)
end

T["retro denylist"]["detects a changed denylist"] = function()
    local dir = make_dir()
    install(dir)
    patterns.save(dir, { denylist = { "j" }, groups = {} })

    MiniTest.expect.equality(usage.denylist_drifted(), false, "nothing applied yet, so nothing to drift from")
    store.write_applied_denylist(dir, "testhost", { "j" })
    MiniTest.expect.equality(usage.denylist_drifted(), false)

    patterns.save(dir, { denylist = { "j", "k" }, groups = {} })
    MiniTest.expect.equality(usage.denylist_drifted(), true, "a new pattern needs a retro pass")
end

T["capture"] = MiniTest.new_set()

T["capture"]["skips a denied key at capture time"] = function()
    local dir = make_dir()
    vim.fn.mkdir(dir, "p")
    patterns.save(dir, { denylist = { "<leader>zd" }, groups = {} })
    install(dir)

    vim.keymap.set("n", "<leader>zd", function() end, { desc = "Denied" })
    invoke("<leader>zd")
    usage.flush()

    MiniTest.expect.equality(#map_events(dir), 0, "denied keys never reach disk")
    vim.keymap.del("n", "<leader>zd")
end

T["capture"]["omits the host from each event"] = function()
    local dir = make_dir()
    install(dir)

    vim.keymap.set("n", "<leader>zh", function() end)
    invoke("<leader>zh")
    usage.flush()

    local events = map_events(dir)
    MiniTest.expect.equality(#events, 1)
    MiniTest.expect.equality(events[1].host, nil, "the filename already carries the host")
    vim.keymap.del("n", "<leader>zh")
end

T["map echo"] = MiniTest.new_set()

-- Typing "dd" fires the dd keymap and also assembles as the motion "dd". Both describe
-- one keypress, so the motion is dropped and the map event (which carries the desc)
-- stands. record_motion is the same entry point install() hands to the sampler.
T["map echo"]["drops a motion that repeats the keymap just fired"] = function()
    local dir = make_dir()
    install(dir)

    vim.keymap.set("n", "<leader>zm", function() end, { desc = "Echoed" })
    invoke("<leader>zm")
    -- The sampler sees the keys the map consumed; " zm" is <leader>zm expanded.
    usage.record_motion(" zm")
    usage.flush()

    local events = read_events(store.raw_path(dir, "testhost", store.month_of(os.time())))
    local kinds = vim.tbl_map(function(e) return e.kind end, events)
    MiniTest.expect.equality(kinds, { "map" }, "the motion echo must not be counted a second time")

    vim.keymap.del("n", "<leader>zm")
end

T["map echo"]["keeps a motion that no keymap fired"] = function()
    local dir = make_dir()
    install(dir)

    usage.record_motion("ciw")
    usage.flush()

    local events = read_events(store.raw_path(dir, "testhost", store.month_of(os.time())))
    MiniTest.expect.equality(#events, 1)
    MiniTest.expect.equality(events[1].kind, "motion")
    MiniTest.expect.equality(events[1].key, "c*w", "grouped onto its family")
end

T["noise suggestions"] = MiniTest.new_set()

T["noise suggestions"]["ranks noisy ungrouped motions"] = function()
    local rows = {
        { kind = "motion", key = "x", count = 90, last = 1 },
        { kind = "motion", key = "c*w", count = 80, last = 1 },
        { kind = "map", key = "<leader>ff", count = 70, last = 1 },
        { kind = "motion", key = "p", count = 5, last = 1 },
    }
    local noisy = report.noise(rows, { min_count = 20 })

    MiniTest.expect.equality(#noisy, 1, "only ungrouped motions past the threshold qualify")
    MiniTest.expect.equality(noisy[1].key, "x")
end

T["noise suggestions"]["never writes patterns.json"] = function()
    local dir = make_dir()
    vim.fn.mkdir(dir, "p")
    patterns.save(dir, { denylist = { "j" }, groups = {} })

    report.noise({ { kind = "motion", key = "x", count = 99, last = 1 } })

    MiniTest.expect.equality(patterns.load(dir).denylist, { "j" }, "suggestions are read-only")
end

if MiniTest.current.all_cases == nil then MiniTest.run() end

return T
