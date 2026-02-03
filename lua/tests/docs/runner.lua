local M = {}

local helpers = require("tests.helpers")

--- Parse .snap file into table keyed by test name
function M.load_snapshots(fixture_path)
    -- TODO: Parse amber-style format (Phase 2)
    -- Will use: local snap_path = fixture_path:gsub("%.lua$", ".snap")
    -- Return: { ["grammar > test name"] = { before, cursor, keys, after, cursor_after, highlights? } }
    _ = fixture_path
    return {}
end

--- Write snapshots table to .snap file
function M.save_snapshots(fixture_path, snapshots)
    -- TODO: Write amber-style format (Phase 2)
    -- Will use: local snap_path = fixture_path:gsub("%.lua$", ".snap")
    _, _ = fixture_path, snapshots
end

--- Capture current editor state
function M.capture_state(ctx)
    return {
        before = ctx.before,
        cursor = ctx.cursor,
        keys = ctx.keys,
        after = vim.api.nvim_buf_get_lines(ctx.bufnr, 0, -1, false),
        cursor_after = { unpack(vim.api.nvim_win_get_cursor(0)) },
        -- highlights = M.capture_highlights(ctx.bufnr),  -- Phase 2
    }
end

--- Run a single test case
function M.run_test(test, grammar_pattern, snapshots, update_mode)
    local MiniTest = require("mini.test")
    local snap_key = grammar_pattern .. " > " .. test.name

    local bufnr = helpers.create_test_buffer(test.before, "text")
    vim.api.nvim_set_current_buf(bufnr)
    vim.api.nvim_win_set_cursor(0, test.cursor or { 1, 0 })

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
    if test.expect.lines then
        local actual = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
        MiniTest.expect.equality(actual, test.expect.lines)
    end

    if test.expect.cursor then
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

    helpers.delete_buffer(bufnr)
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
