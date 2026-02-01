-- Clone 'mini.nvim' manually in a way that it gets managed by 'mini.deps'
local path_package = vim.fn.stdpath("data") .. "/site/"
local mini_path = path_package .. "pack/deps/start/mini.nvim"
if not vim.loop.fs_stat(mini_path) then
    vim.cmd('echo "Installing `mini.nvim`" | redraw')
    local clone_cmd = {
        "git",
        "clone",
        "--filter=blob:none",
        "https://github.com/echasnovski/mini.nvim",
        mini_path,
    }
    vim.fn.system(clone_cmd)
    vim.cmd("packadd mini.nvim | helptags ALL")
    vim.cmd('echo "Installed `mini.nvim`" | redraw')
end

require("mini.deps").setup({
    silent = true, -- Only show ERROR and WARN messages, suppress INFO (snapshots, etc.)
})

require("kyleking.deps.bars-and-lines")
require("kyleking.deps.buffer")
require("kyleking.deps.color")
require("kyleking.deps.colorscheme")
require("kyleking.deps.editing-support")
require("kyleking.deps.file-explorer")
require("kyleking.deps.formatting")
require("kyleking.deps.fuzzy-finder")
require("kyleking.deps.git")
require("kyleking.deps.keybinding")
require("kyleking.deps.lsp")
require("kyleking.deps.motion")
require("kyleking.deps.search")
require("kyleking.deps.split-and-window")
require("kyleking.deps.syntax")
require("kyleking.deps.terminal-integration")
require("kyleking.deps.utility")
require("kyleking.deps.local")

local MiniDeps = require("mini.deps")
local _add, now, later = MiniDeps.add, MiniDeps.now, MiniDeps.later

-- Store the last test run results for re-running failed tests
local last_test_run = {
    results = {},
    failed_tests = {}, -- Format: { {file = "file_path", case_name = "case_name"}, ... }
    has_failures = false,
}

-- Run all mini.test test files
-- Returns a table with test results
local function run_all_tests(only_failed)
    local MiniTest = require("mini.test")
    local test_dir = vim.fn.stdpath("config") .. "/lua/tests"
    local test_results = {}
    local total_passed = 0
    local total_failed = 0
    local total_tests = 0
    local new_failed_tests = {}

    -- Create a floating window for the test output
    local buf = vim.api.nvim_create_buf(false, true)
    local width = math.floor(vim.o.columns * 0.8)
    local height = math.floor(vim.o.lines * 0.8)
    vim.api.nvim_open_win(buf, true, {
        relative = "editor",
        width = width,
        height = height,
        row = math.floor((vim.o.lines - height) / 2),
        col = math.floor((vim.o.columns - width) / 2),
        style = "minimal",
        border = "rounded",
    })

    -- Function to append lines to the buffer
    local function append_line(line) vim.api.nvim_buf_set_lines(buf, -1, -1, false, { line }) end

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
        test_files = vim.fn.globpath(test_dir, "*_spec.lua", false, true)
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
            -- Skip to the next file without using goto
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
                            case_name = case_name, -- Use the key as the case_name
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
local function run_failed_tests() return run_all_tests(true) end

-- Load Mini.test explicitly
now(function()
    if vim.fn.getcwd() == vim.fn.stdpath("config") then
        require("mini.test").setup({
            -- Directory to store baseline files
            baseline_dir = vim.fn.expand("~/.config/nvim/mini-deps-snap"),
            -- Whether to print case timing in verbose mode
            print_case_timing = true,
            -- Stop immediately after these errors
            stop_on_error = {
                summary = true, -- Stop after first error in summary
            },
        })

        -- Add commands to run tests
        vim.api.nvim_create_user_command(
            "RunAllTests",
            function() run_all_tests(false) end,
            { desc = "Run all Mini.test test files" }
        )

        vim.api.nvim_create_user_command(
            "RunFailedTests",
            function() run_failed_tests() end,
            { desc = "Run only failed tests from last run" }
        )

        -- Add keymaps to run tests
        vim.keymap.set("n", "<leader>ta", function() run_all_tests(false) end, { desc = "Run all tests" })
        vim.keymap.set("n", "<leader>tf", function() run_failed_tests() end, { desc = "Run failed tests" })
    end
end)

-- now(function()
--     require("mini.notify").setup()
--     vim.notify = require("mini.notify").make_notify()
-- end)
-- now(function() require("mini.icons").setup() end)
-- now(function() require("mini.tabline").setup() end)
-- now(function() require("mini.statusline").setup() end)

-- later(function() require("mini.ai").setup() end)
-- later(function() require("mini.comment").setup() end)
-- later(function() require("mini.pick").setup() end)

-- Save Mini.Deps snapshot when run from config directory (but not for temp sessions)
later(function()
    if vim.fn.getcwd() == vim.fn.stdpath("config") then
        -- Don't save snapshot for temp sessions (would exclude lualine)
        local utils = require("kyleking.utils")
        local is_temp_session = utils.detect_temp_session()

        if not is_temp_session then
            vim.defer_fn(function() vim.cmd("DepsSnapSave") end, 1000) -- 1 second delay
        end
    end
end)
