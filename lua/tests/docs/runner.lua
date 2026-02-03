local M = {}

local helpers = require("tests.helpers")

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
            MiniTest.expect.equality(actual, expected, "Snapshot mismatch: " .. snap_key)
            snapshots._used[snap_key] = true
        end
    end

    if bufnr then helpers.delete_buffer(bufnr) end
end

--- Run all tests in a fixture
function M.run_fixture(fixture_path)
    local fixture = dofile(fixture_path)
    local snapshots = M.load_snapshots(fixture_path)
    snapshots._used = {}
    snapshots._dirty = false

    local update_mode = vim.env.UPDATE_SNAPSHOTS == "1"

    for _, grammar in ipairs(fixture.grammars) do
        for _, test in ipairs(grammar.tests) do
            M.run_test(test, grammar.pattern, snapshots, update_mode)
        end
    end

    -- Prune unused snapshots in update mode
    if update_mode and snapshots._dirty then
        for key in pairs(snapshots) do
            if key:sub(1, 1) ~= "_" and not snapshots._used[key] then snapshots[key] = nil end
        end
        M.save_snapshots(fixture_path, snapshots)
    end
end

return M
