local MiniTest = require("mini.test")
local cold = require("kyleking.utils.usage.cold")
local patterns = require("kyleking.utils.usage.patterns")

local tmp_dirs = {}
local tmp_maps = {}

local function make_dir()
    local dir = vim.fn.tempname()
    tmp_dirs[#tmp_dirs + 1] = dir
    vim.fn.mkdir(dir, "p")
    return dir
end

-- Every test map is set through the plain API and deleted in post_case, so the suite
-- stays hermetic under random order.
local function map(lhs, desc)
    vim.keymap.set("n", lhs, function() end, { desc = desc })
    tmp_maps[#tmp_maps + 1] = lhs
end

local function write_log(dir, host, events)
    local fh = assert(io.open(("%s/%s.jsonl"):format(dir, host), "w"))
    for _, event in ipairs(events) do
        fh:write(vim.json.encode(event), "\n")
    end
    fh:close()
end

local function find(rows, key)
    local normalized = cold.normalize(key)
    for _, row in ipairs(rows) do
        if row.kind == "map" and cold.normalize(row.key) == normalized then return row end
    end
    return nil
end

--- Only the rows this test created, in the order cold() ranked them.
local function only(rows, keys)
    local wanted = {}
    for _, key in ipairs(keys) do
        wanted[cold.normalize(key)] = true
    end
    return vim.tbl_map(
        function(row) return row.key end,
        vim.tbl_filter(function(row) return wanted[cold.normalize(row.key)] == true end, rows)
    )
end

local JUNE = os.time({ year = 2026, month = 6, day = 15, hour = 12 })
local JULY = os.time({ year = 2026, month = 7, day = 15, hour = 12 })

local T = MiniTest.new_set({
    hooks = {
        post_case = function()
            for _, lhs in ipairs(tmp_maps) do
                pcall(vim.keymap.del, "n", lhs)
            end
            tmp_maps = {}
            for _, dir in ipairs(tmp_dirs) do
                vim.fn.delete(dir, "rf")
            end
            tmp_dirs = {}
        end,
    },
})

T["registered"] = MiniTest.new_set()

T["registered"]["lists a map with its desc"] = function()
    map("<leader>zcr", "Cold registered")

    local row = assert(find(cold.registered(), "<leader>zcr"), "a freshly set map must show up in the live snapshot")
    MiniTest.expect.equality(row.desc, "Cold registered")
    MiniTest.expect.equality(row.kind, "map")
end

T["registered"]["hands back the leader already expanded"] = function()
    map("<leader>zcx", "Expanded lhs")

    local row = assert(find(cold.registered(), "<leader>zcx"))
    MiniTest.expect.equality(
        row.key,
        vim.g.mapleader .. "zcx",
        "this mismatch with the logged lhs is what normalize() has to bridge"
    )
end

T["registered"]["skips plugin-internal mappings"] = function()
    vim.keymap.set("n", "<Plug>(usage-cold-test)", function() end)

    local internal = vim.tbl_filter(function(row) return row.key:find("<Plug>", 1, true) ~= nil end, cold.registered())
    MiniTest.expect.equality(#internal, 0, "<Plug> targets are not things I type")

    pcall(vim.keymap.del, "n", "<Plug>(usage-cold-test)")
end

T["registered"]["deduplicates a key registered in several modes"] = function()
    vim.keymap.set({ "n", "x" }, "<leader>zcd", function() end, { desc = "Multi-mode" })
    tmp_maps[#tmp_maps + 1] = "<leader>zcd"

    local hits = vim.tbl_filter(
        function(row) return cold.normalize(row.key) == cold.normalize("<leader>zcd") end,
        cold.registered()
    )
    MiniTest.expect.equality(#hits, 1, "one lhs is one decision, however many modes it covers")

    pcall(vim.keymap.del, "x", "<leader>zcd")
end

T["cold"] = MiniTest.new_set()

T["cold"]["reports an unlogged map as never used"] = function()
    local dir = make_dir()
    map("<leader>zcn", "Never used")

    local row = assert(find(cold.cold(dir), "<leader>zcn"))
    MiniTest.expect.equality(row.count, 0)
    MiniTest.expect.equality(row.last, 0, "count 0 and last 0 read as never triggered")
end

T["cold"]["matches a logged <leader> map against its expanded lhs"] = function()
    local dir = make_dir()
    map("<leader>zcu", "Used once")
    write_log(dir, "mbp", { { kind = "map", key = "<leader>zcu", desc = "Used once", ts = JULY } })

    local row = assert(find(cold.cold(dir), "<leader>zcu"))
    MiniTest.expect.equality(row.count, 1, "the log stores <leader>zcu while the keymap reads ' zcu'")
    MiniTest.expect.equality(row.last, JULY)
end

T["cold"]["matches a logged control key across case variants"] = function()
    local dir = make_dir()
    map("<C-\\><C-z>", "Ctrl map")
    write_log(dir, "mbp", { { kind = "map", key = "<C-\\><C-Z>", ts = JULY } })

    MiniTest.expect.equality(find(cold.cold(dir), "<C-\\><C-z>").count, 1, "<C-z> and <C-Z> are one key")
end

T["cold"]["ranks never-used before used-once before used-often"] = function()
    local dir = make_dir()
    map("<leader>zc1", "Never")
    map("<leader>zc2", "Once")
    map("<leader>zc3", "Often")
    write_log(dir, "mbp", {
        { kind = "map", key = "<leader>zc2", ts = JULY },
        { kind = "map", key = "<leader>zc3", ts = JULY },
        { kind = "map", key = "<leader>zc3", ts = JULY },
    })

    local ordered = only(cold.cold(dir), { "<leader>zc1", "<leader>zc2", "<leader>zc3" })
    MiniTest.expect.equality(ordered, {
        vim.g.mapleader .. "zc1",
        vim.g.mapleader .. "zc2",
        vim.g.mapleader .. "zc3",
    })
end

T["cold"]["breaks a count tie by the older last-used"] = function()
    local dir = make_dir()
    map("<leader>zco", "Old")
    map("<leader>zcy", "Recent")
    write_log(dir, "mbp", {
        { kind = "map", key = "<leader>zcy", ts = JULY },
        { kind = "map", key = "<leader>zco", ts = JUNE },
    })

    local ordered = only(cold.cold(dir), { "<leader>zco", "<leader>zcy" })
    MiniTest.expect.equality(ordered, {
        vim.g.mapleader .. "zco",
        vim.g.mapleader .. "zcy",
    }, "the one dropped longest ago is the colder decision")
end

T["cold"]["omits a denied key"] = function()
    local dir = make_dir()
    patterns.save(dir, { denylist = { "<leader>zcq" }, groups = {} })
    map("<leader>zcq", "Denied")
    map("<leader>zck", "Kept")

    local rows = cold.cold(dir)
    MiniTest.expect.equality(find(rows, "<leader>zcq"), nil, "denied keys are noise, not cold features")
    MiniTest.expect.equality(find(rows, "<leader>zck") ~= nil, true)
end

T["cold"]["lists a registered user command"] = function()
    local dir = make_dir()
    vim.api.nvim_create_user_command("UsageColdTestCmd", function() end, { desc = "Cold cmd" })

    local rows = cold.cold(dir)
    local hit = nil
    for _, row in ipairs(rows) do
        if row.kind == "cmd" and row.key == "UsageColdTestCmd" then hit = row end
    end
    hit = assert(hit, "user commands reconcile the same way maps do")
    MiniTest.expect.equality(hit.count, 0)

    pcall(vim.api.nvim_del_user_command, "UsageColdTestCmd")
end

T["cold"]["degrades gracefully on a missing directory"] = function()
    map("<leader>zcm", "Never")

    local rows = cold.cold(vim.fn.tempname() .. "/does-not-exist")
    MiniTest.expect.equality(find(rows, "<leader>zcm").count, 0, "no log means everything reads as never used")
end

T["render"] = MiniTest.new_set()

T["render"]["separates never-used from tried-then-dropped"] = function()
    local rows = {
        { kind = "map", key = "<leader>zc1", desc = "Never", count = 0, last = 0 },
        { kind = "map", key = "<leader>zc2", desc = "Dropped", count = 3, last = JUNE },
    }

    local lines = cold.render(rows)
    MiniTest.expect.equality(lines[1]:find("1 of 2 registered never used", 1, true) ~= nil, true)
    MiniTest.expect.equality(lines[3]:find("never", 1, true) ~= nil, true, "count 0 has no meaningful date")
    MiniTest.expect.equality(
        lines[4]:find(os.date("%Y-%m-%d", JUNE) --[[@as string]], 1, true) ~= nil,
        true,
        "a dropped map is dated so it reads differently from one never discovered"
    )
end

T["render"]["honors the limit"] = function()
    local rows = {}
    for i = 1, 5 do
        rows[i] = { kind = "map", key = "k" .. i, count = 0, last = 0 }
    end

    MiniTest.expect.equality(#cold.render(rows, 2), 4, "header, blank line, two rows")
end

T["render"]["handles an empty list"] = function()
    MiniTest.expect.equality(cold.render({}), { "Nothing registered to reconcile." })
end

if MiniTest.current.all_cases == nil then MiniTest.run() end

return T
