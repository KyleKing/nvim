-- Test runner for mini.test
-- Collects spec files, executes them in one batch, and reports a per-file tally.
--
-- Two mini.test details drive the shape of this file:
-- - `MiniTest.execute` runs cases through `vim.schedule` and returns nothing, so a tally
--   has to be read off the case list after the queue drains, not off a return value
-- - the headless stdout reporter quits Neovim when it finishes, so running one file per
--   `MiniTest.run_file` call ends the process at the first file and silently drops the rest

local M = {}

local TEST_DIR = vim.fn.stdpath("config") .. "/lua/tests"
local EXECUTE_TIMEOUT_MS = 600000

-- A spec opts out of the default run by putting `-- @ci-skip: <reason>` in its header.
-- Only two things earn the directive: the spec needs a host tool or a language server CI
-- does not have, or it asserts wall-clock behavior that is unreliable off this machine.
local CI_SKIP_HEADER_LINES = 10

-- Store the last test run results for re-running failed tests
local last_test_run = {
    failed_tests = {}, -- Format: { {file = "file_path", id = "full case id"}, ... }
    has_failures = false,
}

local function is_headless() return #vim.api.nvim_list_uis() == 0 end

local function emit(line) print(line) end

-- Full description of a case; its first element is the file it was collected from
local function case_id(case) return table.concat(case.desc, " | ") end

local function case_failed(case) return type(case.exec) ~= "table" or #case.exec.fails > 0 end

--- Collect cases from the given files without touching the global collect config.
--- Every spec ends with `if ... == nil then MiniTest.run() end` and mini.test collects by
--- `dofile`, where `...` is nil, so a globally installed `find_files` would make each
--- collected file start a run that collects it again. Passing `find_files` per call keeps
--- that nested run on mini.test's default glob, which matches nothing here and terminates.
local function collect_cases(files, filter_cases)
    local MiniTest = require("mini.test")
    return MiniTest.collect({
        find_files = function() return files end,
        filter_cases = filter_cases,
    })
end

--- Execute cases and block until the scheduled queue drains.
---@return boolean finished False if execution timed out
local function execute_cases(cases)
    local MiniTest = require("mini.test")
    -- quit_on_finish would end the process before the summary below is printed
    local reporter = is_headless() and MiniTest.gen_reporter.stdout({ quit_on_finish = false }) or nil

    MiniTest.execute(cases, { reporter = reporter })
    return vim.wait(EXECUTE_TIMEOUT_MS, function() return not MiniTest.is_executing() end, 10)
end

--- Print one summary line per collected file plus a totals block.
---@return table summary {total, passed, failed, failed_tests}
local function report(files, cases)
    local per_file = {}
    for _, file in ipairs(files) do
        per_file[file] = { passed = 0, failed = 0 }
    end

    local failed_tests = {}
    local total, passed, failed = 0, 0, 0
    for _, case in ipairs(cases) do
        local file = case.desc[1]
        local tally = per_file[file] or { passed = 0, failed = 0 }
        per_file[file] = tally
        total = total + 1
        if case_failed(case) then
            failed = failed + 1
            tally.failed = tally.failed + 1
            table.insert(failed_tests, { file = file, id = case_id(case) })
        else
            passed = passed + 1
            tally.passed = tally.passed + 1
        end
    end

    emit("")
    emit("==== Per-file results ====")
    for _, file in ipairs(files) do
        local tally = per_file[file]
        local relative = file:match("lua/tests/(.+)$") or file
        emit(string.format("%s: %d passed, %d failed", relative, tally.passed, tally.failed))
    end

    emit("")
    emit("==== Test Summary ====")
    emit("Files: " .. #files)
    emit("Total tests: " .. total)
    emit("Passed: " .. passed)
    emit("Failed: " .. failed)

    return { total = total, passed = passed, failed = failed, failed_tests = failed_tests }
end

--- Run the given spec files as a single batch.
--- Quits with a non-zero code on failure when headless so a task runner sees the failure.
---@param files string[] Spec file paths
---@param filter_cases function|nil `MiniTest.collect` case filter
---@return table summary
local function run_files(files, filter_cases)
    if #files == 0 then
        emit("No test files found")
        return { total = 0, passed = 0, failed = 0, failed_tests = {} }
    end

    local cases = collect_cases(files, filter_cases)
    local finished = execute_cases(cases)
    local summary = report(files, cases)

    if not finished then
        emit(string.format("TIMEOUT: execution did not finish within %d ms", EXECUTE_TIMEOUT_MS))
        summary.failed = summary.failed + 1
    end

    last_test_run.failed_tests = summary.failed_tests
    last_test_run.has_failures = #summary.failed_tests > 0

    if summary.failed > 0 then
        emit("")
        emit("Use :RunFailedTests or <leader>tf to re-run only failed tests")
        if is_headless() then vim.cmd("silent! 1cquit") end
    end

    return summary
end

--- Run an explicit list of spec files (used by the coverage script)
---@param files string[] Spec file paths
function M.run_files(files) return run_files(files) end

--- Run all mini.test spec files
---@param only_failed boolean Whether to run only failed cases from the last run
---@param shuffle boolean Whether to shuffle file order
---@param seed number|nil Random seed for shuffling
---@return table summary
function M.run_all_tests(only_failed, shuffle, seed)
    local files, filter_cases = {}, nil

    if only_failed then
        if not last_test_run.has_failures then
            emit("No failed tests from previous run.")
            return { total = 0, passed = 0, failed = 0, failed_tests = {} }
        end

        local seen, wanted = {}, {}
        for _, failed_test in ipairs(last_test_run.failed_tests) do
            wanted[failed_test.id] = true
            if not seen[failed_test.file] then
                seen[failed_test.file] = true
                table.insert(files, failed_test.file)
            end
        end
        -- `MiniTest.run` ignores a top-level `filter` key; the filter belongs to `collect`
        filter_cases = function(case) return wanted[case_id(case)] == true end
        emit("Re-running failed tests from last run...")
    else
        files = vim.fn.globpath(TEST_DIR, "**/*_spec.lua", false, true)
        emit("Running all Mini.Tests...")
    end

    if shuffle then
        seed = seed or os.time()
        emit(string.format("Random order (seed: %d)", seed))
        math.randomseed(seed)
        for i = #files, 2, -1 do
            local j = math.random(i)
            files[i], files[j] = files[j], files[i]
        end
    end

    return run_files(files, filter_cases)
end

--- Run only the failed cases from the last run
function M.run_failed_tests() return M.run_all_tests(true, false) end

-- Run every spec across background nvim processes, one chunk of files each.
-- Each worker is a plain `nvim --headless -c luafile`: it gets its whole chunk written
-- out as a script up front and reports through its log file. There is no channel back,
-- which is why the tally below is scraped rather than returned.
-- @param shuffle boolean Whether to shuffle test order
-- @param seed number|nil Random seed for shuffling
-- @return table Test results
function M.run_tests_parallel(shuffle, seed)
    local test_dir = vim.fn.stdpath("config") .. "/lua/tests"
    local test_files = vim.fn.globpath(test_dir, "**/*_spec.lua", false, true)

    if #test_files == 0 then
        print("No test files found in " .. test_dir)
        return {}
    end

    -- Shuffle if requested
    if shuffle then
        seed = seed or os.time()
        math.randomseed(seed)
        print(string.format("Running tests in random order (seed: %d)", seed))

        -- Fisher-Yates shuffle
        for i = #test_files, 2, -1 do
            local j = math.random(i)
            test_files[i], test_files[j] = test_files[j], test_files[i]
        end
    end

    -- available_parallelism reads the cgroup CPU quota where there is one, so a CI
    -- container reports what it may actually use rather than what the host has.
    local num_workers = math.max(1, vim.uv.available_parallelism())
    print(string.format("Starting %d workers for %d test files...", num_workers, #test_files))

    local work_dir = vim.fn.tempname() .. "-test-workers"
    vim.fn.mkdir(work_dir, "p")

    -- Split test files into chunks for workers
    local chunks = {}
    for i = 1, num_workers do
        chunks[i] = {}
    end

    for i, file in ipairs(test_files) do
        local worker_id = ((i - 1) % num_workers) + 1
        table.insert(chunks[worker_id], file)
    end

    -- Create result buffer
    local buf = vim.api.nvim_create_buf(false, true)
    local ui = require("kyleking.utils.ui")
    vim.api.nvim_open_win(
        buf,
        true,
        ui.create_centered_window({
            relative = "editor",
            style = "minimal",
        })
    )

    local function append_line(line)
        local lines = vim.split(line, "\n", { plain = true })
        if vim.api.nvim_buf_is_valid(buf) then vim.api.nvim_buf_set_lines(buf, -1, -1, false, lines) end
        -- A headless run has no window to read the buffer in
        if #vim.api.nvim_list_uis() == 0 then print(line) end
    end

    append_line(string.format("Running %d tests across %d workers...", #test_files, num_workers))
    if shuffle then append_line(string.format("Random order (seed: %d)", seed)) end
    append_line("")

    -- Run tests in parallel using background jobs
    local results = {}
    local worker_processes = {}

    for worker_id, file_chunk in ipairs(chunks) do
        -- Create script for this worker
        local script_path = string.format("%s/worker-%d-script.lua", work_dir, worker_id)
        local script_content = {}

        table.insert(script_content, "local MiniTest = require('mini.test')")
        table.insert(script_content, "local helpers = require('tests.helpers')")
        table.insert(script_content, "vim.wait(10)") -- Brief wait for plugins (NVIM_TEST_SYNC makes this fast)

        for _, test_file in ipairs(file_chunk) do
            local file_name = vim.fn.fnamemodify(test_file, ":t")
            table.insert(script_content, string.format("print('=== Running %s ===')", file_name))
            -- The stdout reporter quits Neovim once a file finishes, which would drop
            -- every later file in this worker's chunk
            table.insert(
                script_content,
                string.format(
                    "MiniTest.run_file('%s', {execute = {reporter = MiniTest.gen_reporter.stdout({quit_on_finish = false})}})",
                    test_file
                )
            )
            table.insert(
                script_content,
                [[
                -- run_file returns nothing and executes asynchronously, so read the
                -- outcome off the case list once the queue drains
                vim.wait(300000, function() return not MiniTest.is_executing() end, 10)
                local passed = 0
                local failed = 0
                for _, case in ipairs(MiniTest.current.all_cases or {}) do
                    local fails = type(case.exec) == 'table' and case.exec.fails or {}
                    if #fails == 0 then passed = passed + 1 else failed = failed + 1 end
                end
                print(string.format('Results: %d passed, %d failed', passed, failed))
            ]]
            )
            table.insert(script_content, "helpers.full_cleanup()")
        end

        table.insert(script_content, "print('=== Worker complete ===')")
        table.insert(script_content, "vim.cmd('qall!')")

        local f = io.open(script_path, "w")
        if f then
            f:write(table.concat(script_content, "\n"))
            f:close()
        end

        -- Start worker process
        local log_path = string.format("%s/worker-%d.log", work_dir, worker_id)
        local cmd = {
            "nvim",
            "--headless",
            "-c",
            string.format("luafile %s", script_path),
        }

        if vim.env.NVIM_TEST_SYNC then cmd = { "env", "NVIM_TEST_SYNC=1", unpack(cmd) } end

        -- Redirect output to log file
        local log_file = io.open(log_path, "w")
        local proc = {
            log_path = log_path,
            log_file = log_file,
            chunk = file_chunk,
        }
        -- Completion has to come from on_exit: job:wait(0) does not poll, it kills the
        -- process the moment the timeout expires, so every worker died before running
        proc.job = vim.system(cmd, {
            text = true,
            stdout = function(_, data)
                if log_file and data then log_file:write(data) end
            end,
            stderr = function(_, data)
                if log_file and data then log_file:write(data) end
            end,
        }, function() proc.exited = true end)
        worker_processes[worker_id] = proc
    end

    -- Wait for all workers to complete
    append_line("Workers running...")
    for worker_id, proc in ipairs(worker_processes) do
        vim.wait(600000, function() return proc.exited end, 25)
        proc.log_file:close()
        append_line(string.format("[Worker %d] Completed", worker_id))
    end

    -- Parse results from log files
    append_line("")
    append_line("=== Results ===")
    local started, reported, passed, failed = 0, 0, 0, 0
    for worker_id, proc in ipairs(worker_processes) do
        local log = vim.fn.readfile(proc.log_path)
        for _, line in ipairs(log) do
            if line:match("^=== Running") then started = started + 1 end
            local file_passed, file_failed = line:match("^Results: (%d+) passed, (%d+) failed")
            if file_passed then
                reported = reported + 1
                passed = passed + tonumber(file_passed)
                failed = failed + tonumber(file_failed)
            end
            if line:match("^=== Running") or line:match("^Results:") then
                append_line(string.format("[W%d] %s", worker_id, line))
            end
        end
    end

    append_line("")
    append_line("==== Test Summary ====")
    append_line(string.format("Files: %d of %d reported", reported, #test_files))
    append_line("Passed: " .. passed)
    append_line("Failed: " .. failed)

    -- A file that started without reporting means its worker died mid-chunk
    local incomplete = started - reported
    if incomplete > 0 then append_line(string.format("Files that started but never reported: %d", incomplete)) end

    if is_headless() and (failed > 0 or incomplete > 0 or reported < #test_files) then vim.cmd("silent! 1cquit") end

    append_line("Press 'q' or <Esc> to close")

    vim.api.nvim_buf_set_keymap(buf, "n", "q", "<Cmd>close<CR>", { noremap = true, silent = true })
    vim.api.nvim_buf_set_keymap(buf, "n", "<Esc>", "<Cmd>close<CR>", { noremap = true, silent = true })

    vim.fn.delete(work_dir, "rf")
    return results
end

--- Run fast tests (excludes subprocess-heavy and slow integration tests)
--- Designed for rapid development feedback (~10-15 seconds)
function M.run_fast_tests()
    -- Fast test files: no subprocess spawning, minimal external dependencies
    local fast_test_patterns = {
        -- Core tests (excluding subprocess smoke test)
        -- "lua/tests/core/smoke_spec.lua", -- Excluded: spawns subprocess

        -- All custom utility tests (fast, pure Lua)
        "lua/tests/custom/constants_spec.lua",
        "lua/tests/custom/noqa_spec.lua",
        "lua/tests/custom/utils_spec.lua",
        "lua/tests/custom/window_focus_spec.lua",
        "lua/tests/custom/list_editing_spec.lua",
        "lua/tests/custom/ui_spec.lua",
        "lua/tests/custom/clue_help_spec.lua",
        "lua/tests/custom/health_spec.lua",

        -- Plugin config tests (no external tools)
        "lua/tests/plugins/keybinding_spec.lua",
        "lua/tests/plugins/mini_ai_spec.lua",

        -- UI tests (fast config validation)
        "lua/tests/ui/temp_statusline_spec.lua",
        "lua/tests/ui/picker_config_spec.lua",

        -- Fast integration tests
        "lua/tests/integration/clue_keymap_integration_spec.lua",
        "lua/tests/integration/mini_files_operations_spec.lua",
    }

    local test_files = {}
    for _, pattern in ipairs(fast_test_patterns) do
        if vim.fn.filereadable(pattern) == 1 then table.insert(test_files, pattern) end
    end

    print("Running fast tests (" .. #test_files .. " files)...")
    return run_files(test_files)
end

--- Read a spec's `@ci-skip` reason from its header, or nil when it has none.
--- Reading the header keeps discovery cheap: mini.test only loads a spec at collect time,
--- so the runner cannot ask the module for a marker before deciding whether to collect it.
local function ci_skip_reason(file)
    local handle = io.open(file, "r")
    if handle == nil then return nil end

    local reason = nil
    for _ = 1, CI_SKIP_HEADER_LINES do
        local line = handle:read("l")
        if line == nil then break end
        reason = line:match("^%s*%-%-%s*@ci%-skip:%s*(.+)$")
        if reason ~= nil then break end
    end

    handle:close()
    return reason
end

--- Run every spec except the ones whose header opts out with `-- @ci-skip: <reason>`.
--- Discovery is a glob, so a new spec joins this run without being registered anywhere.
function M.run_ci_tests()
    local test_files, skipped = {}, {}
    for _, file in ipairs(vim.fn.globpath(TEST_DIR, "**/*_spec.lua", false, true)) do
        local reason = ci_skip_reason(file)
        if reason == nil then
            table.insert(test_files, file)
        else
            table.insert(skipped, { file = file:match("lua/tests/(.+)$") or file, reason = reason })
        end
    end

    print("Running CI-safe tests (" .. #test_files .. " files)...")
    for _, entry in ipairs(skipped) do
        print(string.format("Skipping %s: %s", entry.file, entry.reason))
    end

    return run_files(test_files)
end

return M
