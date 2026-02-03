local M = {}

local helpers = require("tests.helpers")

-- Profiling state
M.profiling = {
    enabled = vim.env.PROFILE_TESTS == "1",
    results = {},
}

--- Format duration in milliseconds to human-readable string
local function format_duration(ms)
    if ms < 1 then
        return string.format("%.2fμs", ms * 1000)
    elseif ms < 1000 then
        return string.format("%.2fms", ms)
    else
        return string.format("%.2fs", ms / 1000)
    end
end

--- Create detailed diff message for snapshot mismatch
local function create_snapshot_diff(actual, expected, snap_key)
    local lines = { "Snapshot mismatch: " .. snap_key, "" }

    -- Compare lines
    if not vim.deep_equal(actual.after, expected.after) then
        table.insert(lines, "Lines differ:")
        table.insert(lines, "  Expected:")
        for _, line in ipairs(expected.after or {}) do
            table.insert(lines, "    " .. line)
        end
        table.insert(lines, "  Actual:")
        for _, line in ipairs(actual.after or {}) do
            table.insert(lines, "    " .. line)
        end
        table.insert(lines, "")
    end

    -- Compare cursor positions
    if not vim.deep_equal(actual.cursor_after, expected.cursor_after) then
        table.insert(
            lines,
            string.format(
                "Cursor position differs: expected [%d, %d], got [%d, %d]",
                expected.cursor_after[1],
                expected.cursor_after[2],
                actual.cursor_after[1],
                actual.cursor_after[2]
            )
        )
        table.insert(lines, "")
    end

    -- Compare highlights
    if not vim.deep_equal(actual.highlights, expected.highlights) then
        table.insert(lines, "Highlights differ:")
        table.insert(lines, "  Expected:")
        for _, hl in ipairs(expected.highlights or {}) do
            table.insert(
                lines,
                string.format(
                    "    %s at [[%d,%d], [%d,%d]]",
                    hl.group,
                    hl.range[1][1],
                    hl.range[1][2],
                    hl.range[2][1],
                    hl.range[2][2]
                )
            )
        end
        table.insert(lines, "  Actual:")
        for _, hl in ipairs(actual.highlights or {}) do
            table.insert(
                lines,
                string.format(
                    "    %s at [[%d,%d], [%d,%d]]",
                    hl.group,
                    hl.range[1][1],
                    hl.range[1][2],
                    hl.range[2][1],
                    hl.range[2][2]
                )
            )
        end
        table.insert(lines, "")
    end

    table.insert(lines, "Run with UPDATE_SNAPSHOTS=1 to update this snapshot.")

    return table.concat(lines, "\n")
end

--- Parse cursor format "[row, col]"
local function parse_cursor(str)
    local row, col = str:match("%[(%d+), (%d+)%]")
    return { tonumber(row), tonumber(col) }
end

--- Parse range format "[[r1, c1], [r2, c2]]"
local function parse_range(str)
    local r1, c1, r2, c2 = str:match("%[%[(%d+), (%d+)%], %[(%d+), (%d+)%]%]")
    return { { tonumber(r1), tonumber(c1) }, { tonumber(r2), tonumber(c2) } }
end

--- Parse .snap file into table keyed by test name
function M.load_snapshots(fixture_path)
    local snap_path = fixture_path:gsub("%.lua$", ".snap")

    if vim.fn.filereadable(snap_path) == 0 then return {} end

    local content = vim.fn.readfile(snap_path)
    local snapshots = {}

    -- Split content into snapshot blocks by "# ---"
    local blocks = {}
    local current_block = {}

    for _, line in ipairs(content) do
        if line == "# ---" then
            if #current_block > 0 then
                table.insert(blocks, current_block)
                current_block = {}
            end
        else
            table.insert(current_block, line)
        end
    end
    if #current_block > 0 then table.insert(blocks, current_block) end

    -- Parse each block
    for _, block in ipairs(blocks) do
        local snapshot = {}
        local name = nil
        local i = 1

        while i <= #block do
            local line = block[i]

            if line:match("^# name: ") then
                name = (line:gsub("^# name: ", ""))
                i = i + 1
            elseif line == "before:" then
                snapshot.before = {}
                i = i + 1
                while i <= #block and block[i]:match("^  ") do
                    table.insert(snapshot.before, (block[i]:gsub("^  ", "")))
                    i = i + 1
                end
            elseif line == "after:" then
                snapshot.after = {}
                i = i + 1
                while i <= #block and block[i]:match("^  ") do
                    table.insert(snapshot.after, (block[i]:gsub("^  ", "")))
                    i = i + 1
                end
            elseif line:match("^cursor: ") then
                snapshot.cursor = parse_cursor((line:gsub("^cursor: ", "")))
                i = i + 1
            elseif line:match("^cursor_after: ") then
                snapshot.cursor_after = parse_cursor((line:gsub("^cursor_after: ", "")))
                i = i + 1
            elseif line:match("^keys: ") then
                snapshot.keys = (line:gsub("^keys: ", ""))
                i = i + 1
            elseif line == "highlights:" then
                snapshot.highlights = {}
                i = i + 1
                while i <= #block and block[i]:match("^  %-") do
                    local highlight = {}
                    highlight.group = (block[i]:gsub("^  %- group: ", ""))
                    i = i + 1
                    if i <= #block and block[i]:match("^    range: ") then
                        highlight.range = parse_range((block[i]:gsub("^    range: ", "")))
                        i = i + 1
                    end
                    table.insert(snapshot.highlights, highlight)
                end
            else
                i = i + 1
            end
        end

        if name then snapshots[name] = snapshot end
    end

    return snapshots
end

--- Write snapshots table to .snap file
function M.save_snapshots(fixture_path, snapshots)
    local snap_path = fixture_path:gsub("%.lua$", ".snap")
    local lines = {}

    -- Sort snapshot keys for deterministic output
    local keys = {}
    for k in pairs(snapshots) do
        if k:sub(1, 1) ~= "_" then table.insert(keys, k) end
    end
    table.sort(keys)

    for i, name in ipairs(keys) do
        local snap = snapshots[name]

        table.insert(lines, "# name: " .. name)
        table.insert(lines, "before:")
        for _, line in ipairs(snap.before or {}) do
            table.insert(lines, "  " .. line)
        end
        if snap.cursor then table.insert(lines, string.format("cursor: [%d, %d]", snap.cursor[1], snap.cursor[2])) end
        if snap.keys then table.insert(lines, "keys: " .. snap.keys) end
        table.insert(lines, "after:")
        for _, line in ipairs(snap.after or {}) do
            table.insert(lines, "  " .. line)
        end
        if snap.cursor_after then
            table.insert(lines, string.format("cursor_after: [%d, %d]", snap.cursor_after[1], snap.cursor_after[2]))
        end

        if snap.highlights and #snap.highlights > 0 then
            table.insert(lines, "highlights:")
            for _, hl in ipairs(snap.highlights) do
                table.insert(lines, "  - group: " .. hl.group)
                local r1, c1 = hl.range[1][1], hl.range[1][2]
                local r2, c2 = hl.range[2][1], hl.range[2][2]
                table.insert(lines, string.format("    range: [[%d, %d], [%d, %d]]", r1, c1, r2, c2))
            end
        end

        if i < #keys then table.insert(lines, "# ---") end
    end

    vim.fn.writefile(lines, snap_path)
end

--- Capture highlight extmarks from buffer
function M.capture_highlights(bufnr)
    local highlights = {}

    -- Get all extmarks from all namespaces with details
    local extmarks = vim.api.nvim_buf_get_extmarks(bufnr, -1, 0, -1, { details = true })

    for _, mark in ipairs(extmarks) do
        local row, col, details = mark[2], mark[3], mark[4]

        if details.hl_group then
            local end_row = details.end_row or row
            local end_col = details.end_col or col

            -- Convert to 1-indexed row (col stays 0-indexed per Neovim convention)
            table.insert(highlights, {
                group = details.hl_group,
                range = { { row + 1, col }, { end_row + 1, end_col } },
            })
        end
    end

    -- Sort by position for deterministic output
    table.sort(highlights, function(a, b)
        if a.range[1][1] ~= b.range[1][1] then return a.range[1][1] < b.range[1][1] end
        return a.range[1][2] < b.range[1][2]
    end)

    return highlights
end

--- Capture current editor state
function M.capture_state(ctx)
    return {
        before = ctx.before,
        cursor = ctx.cursor,
        keys = ctx.keys,
        after = vim.api.nvim_buf_get_lines(ctx.bufnr, 0, -1, false),
        cursor_after = { unpack(vim.api.nvim_win_get_cursor(0)) },
        highlights = M.capture_highlights(ctx.bufnr),
    }
end

--- Run a single test case
function M.run_test(test, grammar_pattern, snapshots, update_mode)
    local MiniTest = require("mini.test")
    local snap_key = grammar_pattern .. " > " .. test.name
    local start_time = M.profiling.enabled and vim.uv.hrtime() or nil

    -- Handle tests without before (for tests that use expect.fn only)
    local bufnr
    if test.before then
        bufnr = helpers.create_test_buffer(test.before, "text")
        vim.api.nvim_set_current_buf(bufnr)
        vim.api.nvim_win_set_cursor(0, test.cursor or { 1, 0 })
    end

    -- Run setup
    if test.setup and test.setup.fn then test.setup.fn() end

    -- Execute keys (using nvim_cmd for proper argument handling)
    if test.keys then vim.api.nvim_cmd({ cmd = "normal", args = { test.keys } }, {}) end
    if test.input then vim.api.nvim_feedkeys(test.input, "tx", false) end

    local ctx = {
        bufnr = bufnr,
        before = test.before,
        cursor = test.cursor or { 1, 0 },
        keys = test.keys,
    }

    -- Assert based on expect type
    if test.expect.lines and bufnr then
        local actual = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
        MiniTest.expect.equality(actual, test.expect.lines)
    end

    if test.expect.cursor and bufnr then
        local actual = vim.api.nvim_win_get_cursor(0)
        MiniTest.expect.equality({ actual[1], actual[2] }, test.expect.cursor)
    end

    if test.expect.fn then test.expect.fn(ctx) end

    if test.expect.snapshot then
        local actual = M.capture_state(ctx)

        if update_mode then
            snapshots[snap_key] = actual
            snapshots._dirty = true
            snapshots._used[snap_key] = true
        else
            local expected = snapshots[snap_key]
            if expected == nil then error("Missing snapshot for: " .. snap_key .. "\nRun with UPDATE_SNAPSHOTS=1") end

            -- Use detailed diff for better error messages
            if not vim.deep_equal(actual, expected) then
                local diff_msg = create_snapshot_diff(actual, expected, snap_key)
                error(diff_msg)
            end
            snapshots._used[snap_key] = true
        end
    end

    if bufnr then helpers.delete_buffer(bufnr) end

    -- Record profiling data
    if M.profiling.enabled and start_time then
        local duration_ns = vim.uv.hrtime() - start_time
        local duration_ms = duration_ns / 1e6
        return { duration_ms = duration_ms }
    end
end

--- Run all tests in a fixture
function M.run_fixture(fixture_path)
    local fixture_start = M.profiling.enabled and vim.uv.hrtime() or nil
    local fixture = dofile(fixture_path)
    local snapshots = M.load_snapshots(fixture_path)
    snapshots._used = {}
    snapshots._dirty = false

    local update_mode = vim.env.UPDATE_SNAPSHOTS == "1"
    local profile_data = {
        fixture = vim.fn.fnamemodify(fixture_path, ":t:r"),
        grammars = {},
        total_tests = 0,
        total_duration_ms = 0,
    }

    for _, grammar in ipairs(fixture.grammars) do
        local grammar_start = M.profiling.enabled and vim.uv.hrtime() or nil
        local grammar_data = {
            pattern = grammar.pattern,
            tests = {},
            duration_ms = 0,
        }

        for _, test in ipairs(grammar.tests) do
            local test_profile = M.run_test(test, grammar.pattern, snapshots, update_mode)
            profile_data.total_tests = profile_data.total_tests + 1

            if M.profiling.enabled and test_profile then
                table.insert(grammar_data.tests, {
                    name = test.name,
                    duration_ms = test_profile.duration_ms,
                })
                grammar_data.duration_ms = grammar_data.duration_ms + test_profile.duration_ms
            end
        end

        if M.profiling.enabled and grammar_start then
            local actual_duration_ns = vim.uv.hrtime() - grammar_start
            grammar_data.duration_ms = actual_duration_ns / 1e6
        end

        if M.profiling.enabled then table.insert(profile_data.grammars, grammar_data) end
    end

    -- Prune unused snapshots in update mode
    if update_mode and snapshots._dirty then
        for key in pairs(snapshots) do
            if key:sub(1, 1) ~= "_" and not snapshots._used[key] then snapshots[key] = nil end
        end
        M.save_snapshots(fixture_path, snapshots)
    end

    -- Calculate total fixture duration
    if M.profiling.enabled and fixture_start then
        local fixture_duration_ns = vim.uv.hrtime() - fixture_start
        profile_data.total_duration_ms = fixture_duration_ns / 1e6
        table.insert(M.profiling.results, profile_data)
    end

    return profile_data
end

--- Print profiling summary
function M.print_profiling_summary()
    if not M.profiling.enabled or #M.profiling.results == 0 then return end

    print("\n=== Fixture Performance Profile ===\n")

    -- Sort fixtures by duration (slowest first)
    local sorted_fixtures = vim.deepcopy(M.profiling.results)
    table.sort(sorted_fixtures, function(a, b) return a.total_duration_ms > b.total_duration_ms end)

    local total_time_ms = 0
    local total_test_count = 0

    for _, fixture in ipairs(sorted_fixtures) do
        total_time_ms = total_time_ms + fixture.total_duration_ms
        total_test_count = total_test_count + fixture.total_tests

        print(
            string.format(
                "%s: %s (%d tests)",
                fixture.fixture,
                format_duration(fixture.total_duration_ms),
                fixture.total_tests
            )
        )

        -- Show slowest grammars in this fixture
        local sorted_grammars = vim.deepcopy(fixture.grammars)
        table.sort(sorted_grammars, function(a, b) return a.duration_ms > b.duration_ms end)

        for _, grammar in ipairs(sorted_grammars) do
            if grammar.duration_ms > 10 then -- Only show grammars taking > 10ms
                print(
                    string.format(
                        "  %s: %s (%d tests)",
                        grammar.pattern,
                        format_duration(grammar.duration_ms),
                        #grammar.tests
                    )
                )
            end
        end
        print("")
    end

    print(
        string.format(
            "Total: %s across %d tests in %d fixtures",
            format_duration(total_time_ms),
            total_test_count,
            #sorted_fixtures
        )
    )
    print(string.format("Average per test: %s", format_duration(total_time_ms / total_test_count)))
end

return M
