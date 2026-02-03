-- Test runner for mini.test
-- Provides functions to run all tests or only failed tests with results displayed in a floating window

local M = {}

-- Store the last test run results for re-running failed tests
local last_test_run = {
    results = {},
    failed_tests = {}, -- Format: { {file = "file_path", case_name = "case_name"}, ... }
    has_failures = false,
}

-- Run all mini.test test files
-- @param only_failed boolean Whether to run only failed tests from last run
-- @param shuffle boolean Whether to shuffle test order
-- @param seed number|nil Random seed for shuffling
-- @return table Test results
function M.run_all_tests(only_failed, shuffle, seed)
    local MiniTest = require("mini.test")
    local test_dir = vim.fn.stdpath("config") .. "/lua/tests"
    local test_results = {}
    local total_passed = 0
    local total_failed = 0
    local total_tests = 0
    local new_failed_tests = {}

    -- Create a floating window for the test output
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

    -- Function to append lines to the buffer
    local function append_line(line)
        local lines = vim.split(line, "\n", { plain = true })
        vim.api.nvim_buf_set_lines(buf, -1, -1, false, lines)
    end

    if only_failed then
        if not last_test_run.has_failures then
            append_line("No failed tests from previous run.")
            append_line("Press 'q' or <Esc> to close this window.")
            vim.api.nvim_buf_set_keymap(buf, "n", "q", ":close<CR>", { noremap = true, silent = true })
            vim.api.nvim_buf_set_keymap(buf, "n", "<Esc>", ":close<CR>", { noremap = true, silent = true })
            return
        end
        append_line("Re-running failed tests from last run...")
    else
        append_line("Running all Mini.Tests...")
    end

    if shuffle then
        seed = seed or os.time()
        append_line(string.format("Random order (seed: %d)", seed))
    end
    append_line("")

    -- Find all test files or use only failed test files
    local test_files = {}
    if only_failed then
        -- Get unique files from failed tests
        local unique_files = {}
        for _, failed_test in ipairs(last_test_run.failed_tests) do
            unique_files[failed_test.file] = true
        end
        for file, _ in pairs(unique_files) do
            table.insert(test_files, file)
        end
    else
        test_files = vim.fn.globpath(test_dir, "**/*_spec.lua", false, true)
    end

    -- Shuffle if requested
    if shuffle then
        math.randomseed(seed)
        -- Fisher-Yates shuffle
        for i = #test_files, 2, -1 do
            local j = math.random(i)
            test_files[i], test_files[j] = test_files[j], test_files[i]
        end
    end

    if #test_files == 0 then
        append_line("No test files found" .. (only_failed and " in last failed run." or " in " .. test_dir))
        append_line("Press 'q' or <Esc> to close this window.")
        vim.api.nvim_buf_set_keymap(buf, "n", "q", ":close<CR>", { noremap = true, silent = true })
        vim.api.nvim_buf_set_keymap(buf, "n", "<Esc>", ":close<CR>", { noremap = true, silent = true })
        return
    end

    for _, test_file in ipairs(test_files) do
        local file_name = vim.fn.fnamemodify(test_file, ":t")
        append_line("==== Running tests from " .. file_name .. " ====")

        -- Clear package cache for the test module
        local module_name = "tests." .. vim.fn.fnamemodify(file_name, ":r")
        package.loaded[module_name] = nil

        -- Load the test module
        local ok, test_module = pcall(require, module_name)
        if not ok then
            append_line("Error loading test module: " .. tostring(test_module))
            test_results[file_name] = { status = "error", error = tostring(test_module) }
            break
        end

        -- Run tests - either all tests in the file or only failed tests
        local test_result
        if only_failed then
            -- Get list of failed cases from this file
            local failed_cases = {}
            for _, failed_test in ipairs(last_test_run.failed_tests) do
                if failed_test.file == test_file then failed_cases[failed_test.case_name] = true end
            end

            -- Run only failed test cases
            test_result = MiniTest.run_file(test_file, {
                verbose = true,
                filter = function(_, _, case_name) return failed_cases[case_name] == true end,
            })
        else
            test_result = MiniTest.run_file(test_file, { verbose = true })
        end

        test_results[file_name] = test_result

        -- Process results for this file
        local file_passed = 0
        local file_failed = 0

        -- Safely iterate through the test results
        if type(test_result) == "table" then
            for case_name, case_result in pairs(test_result) do
                -- Ensure we're only processing valid test case results
                if type(case_result) == "table" and case_result.status then
                    total_tests = total_tests + 1
                    if case_result.status == "pass" then
                        file_passed = file_passed + 1
                        total_passed = total_passed + 1
                    else
                        file_failed = file_failed + 1
                        total_failed = total_failed + 1
                        -- Record failed test for next run
                        table.insert(new_failed_tests, {
                            file = test_file,
                            case_name = case_name,
                        })
                        -- Display details of failed tests
                        append_line("  FAILED: " .. case_name)
                        if case_result.error then append_line("    Error: " .. case_result.error) end
                    end
                end
            end
        else
            append_line("  WARNING: No valid test results returned for " .. file_name)
        end

        append_line("  Results: " .. file_passed .. " passed, " .. file_failed .. " failed")
        append_line("")
    end

    -- Print summary
    append_line("==== Test Summary ====")
    append_line("Total tests: " .. total_tests)
    append_line("Passed: " .. total_passed)
    append_line("Failed: " .. total_failed)

    if total_failed > 0 then
        append_line("")
        append_line("Use :RunFailedTests or <leader>tf to re-run only failed tests")
    end

    -- Add keymaps to close the window
    vim.api.nvim_buf_set_keymap(buf, "n", "q", ":close<CR>", { noremap = true, silent = true })
    vim.api.nvim_buf_set_keymap(buf, "n", "<Esc>", ":close<CR>", { noremap = true, silent = true })

    -- Update last test run status for future failed test runs
    last_test_run.results = test_results
    last_test_run.failed_tests = new_failed_tests
    last_test_run.has_failures = total_failed > 0

    return test_results
end

-- Run only the failed tests from the last run
function M.run_failed_tests() return M.run_all_tests(true) end

-- Parallel worker pool implementation
local WorkerPool = {}
WorkerPool.__index = WorkerPool

-- Create a new worker pool
-- @param num_workers number Number of workers to create
-- @return table Worker pool instance
function WorkerPool.new(num_workers)
    local self = setmetatable({}, WorkerPool)
    self.num_workers = num_workers or 4
    self.workers = {}
    self.socket_dir = vim.fn.tempname() .. "-test-sockets"
    vim.fn.mkdir(self.socket_dir, "p")
    return self
end

-- Start all workers
function WorkerPool:start()
    for i = 1, self.num_workers do
        local socket = string.format("%s/worker-%d.sock", self.socket_dir, i)
        local cmd = {
            "nvim",
            "--headless",
            "--listen",
            socket,
        }

        if vim.env.MINI_DEPS_LATER_AS_NOW then cmd = { "env", "MINI_DEPS_LATER_AS_NOW=1", unpack(cmd) } end

        local job = vim.system(cmd, { detach = true })
        self.workers[i] = {
            id = i,
            socket = socket,
            job = job,
            busy = false,
        }

        -- Wait for socket to be ready
        local max_wait = 5000
        local start = vim.uv.now()
        while vim.uv.now() - start < max_wait do
            if vim.uv.fs_stat(socket) then break end
            vim.wait(50)
        end
    end
end

-- Execute Lua code in a worker via RPC
-- @param worker_id number Worker ID
-- @param lua_code string Lua code to execute
-- @return table Result {success: boolean, output: string, error: string}
function WorkerPool:execute_in_worker(worker_id, lua_code)
    local worker = self.workers[worker_id]
    if not worker then return { success = false, error = "Invalid worker ID" } end

    -- Create temporary file with Lua code
    local tmpfile = vim.fn.tempname() .. ".lua"
    local wrapped = string.format(
        [[
local ok, result = pcall(function()
    %s
end)
if not ok then
    print("ERROR: " .. tostring(result))
end
]],
        lua_code
    )

    local f = io.open(tmpfile, "w")
    if f then
        f:write(wrapped)
        f:close()
    end

    -- Execute via nvim --server
    local cmd = {
        "nvim",
        "--server",
        worker.socket,
        "--remote-send",
        string.format("<Cmd>luafile %s<CR>", tmpfile),
    }

    local result = vim.system(cmd, { text = true }):wait(10000)
    vim.fn.delete(tmpfile)

    return {
        success = result.code == 0,
        output = result.stdout or "",
        error = result.stderr or "",
    }
end

-- Run cleanup in worker
function WorkerPool:cleanup_worker(worker_id)
    local cleanup_code = [[
        local helpers = require("tests.helpers")
        helpers.full_cleanup()
    ]]
    return self:execute_in_worker(worker_id, cleanup_code)
end

-- Stop all workers
function WorkerPool:shutdown()
    for _, worker in ipairs(self.workers) do
        vim.system({ "nvim", "--server", worker.socket, "--remote-send", "<Cmd>qall!<CR>" }):wait(1000)
    end
    vim.fn.delete(self.socket_dir, "rf")
end

-- Run tests in parallel with worker pool
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

    -- Detect CPU cores
    local num_workers = tonumber(vim.fn.system("sysctl -n hw.ncpu"):match("%d+")) or 4
    print(string.format("Starting %d workers for %d test files...", num_workers, #test_files))

    local pool = WorkerPool.new(num_workers)
    pool:start()

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
        vim.api.nvim_buf_set_lines(buf, -1, -1, false, lines)
    end

    append_line(string.format("Running %d tests across %d workers...", #test_files, num_workers))
    if shuffle then append_line(string.format("Random order (seed: %d)", seed)) end
    append_line("")

    -- Run tests in parallel using background jobs
    local results = {}
    local worker_processes = {}

    for worker_id, file_chunk in ipairs(chunks) do
        -- Create script for this worker
        local script_path = string.format("%s/worker-%d-script.lua", pool.socket_dir, worker_id)
        local script_content = {}

        table.insert(script_content, "local MiniTest = require('mini.test')")
        table.insert(script_content, "local helpers = require('tests.helpers')")
        table.insert(script_content, "vim.wait(100)") -- Let plugins initialize

        for _, test_file in ipairs(file_chunk) do
            local file_name = vim.fn.fnamemodify(test_file, ":t")
            table.insert(script_content, string.format("print('=== Running %s ===')", file_name))
            table.insert(
                script_content,
                string.format("local result = MiniTest.run_file('%s', {verbose = false})", test_file)
            )
            table.insert(
                script_content,
                [[
                local passed = 0
                local failed = 0
                for k, v in pairs(result) do
                    if type(v) == 'table' and v.status then
                        if v.status == 'pass' then passed = passed + 1
                        else failed = failed + 1 end
                    end
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
        local log_path = string.format("%s/worker-%d.log", pool.socket_dir, worker_id)
        local cmd = {
            "nvim",
            "--headless",
            "-c",
            string.format("luafile %s", script_path),
        }

        if vim.env.MINI_DEPS_LATER_AS_NOW then cmd = { "env", "MINI_DEPS_LATER_AS_NOW=1", unpack(cmd) } end

        -- Redirect output to log file
        local log_file = io.open(log_path, "w")
        worker_processes[worker_id] = {
            job = vim.system(cmd, {
                text = true,
                stdout = function(_, data)
                    if log_file and data then log_file:write(data) end
                end,
                stderr = function(_, data)
                    if log_file and data then log_file:write(data) end
                end,
            }),
            log_path = log_path,
            log_file = log_file,
            chunk = file_chunk,
        }
    end

    -- Wait for all workers to complete
    append_line("Workers running...")
    local all_complete = false
    while not all_complete do
        all_complete = true
        for worker_id, proc in ipairs(worker_processes) do
            local result = proc.job:wait(0) -- Non-blocking check
            if not result then
                all_complete = false
            elseif not proc.completed then
                proc.completed = true
                proc.log_file:close()
                append_line(string.format("[Worker %d] Completed", worker_id))
            end
        end
        if not all_complete then vim.wait(100) end
    end

    -- Parse results from log files
    append_line("")
    append_line("=== Results ===")
    for worker_id, proc in ipairs(worker_processes) do
        local log = vim.fn.readfile(proc.log_path)
        for _, line in ipairs(log) do
            if line:match("^=== Running") or line:match("^Results:") then
                append_line(string.format("[W%d] %s", worker_id, line))
            end
        end
    end

    append_line("")
    append_line("All tests completed!")
    append_line("Press 'q' or <Esc> to close")

    vim.api.nvim_buf_set_keymap(buf, "n", "q", ":close<CR>", { noremap = true, silent = true })
    vim.api.nvim_buf_set_keymap(buf, "n", "<Esc>", ":close<CR>", { noremap = true, silent = true })

    pool:shutdown()
    return results
end

return M
