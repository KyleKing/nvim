-- Clone 'mini.nvim' manually in a way that it gets managed by 'mini.deps'
local path_package = vim.fn.stdpath("data") .. "/site/"
local mini_path = path_package .. "pack/deps/start/mini.nvim"
if not vim.uv.fs_stat(mini_path) then
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

local MiniDeps = require("mini.deps")

-- For testing: maybe_later uses now() when MINI_DEPS_LATER_AS_NOW=1, otherwise later()
-- This provides explicit control over plugin loading during tests without overriding mini.deps
local maybe_later = vim.env.MINI_DEPS_LATER_AS_NOW and MiniDeps.now or MiniDeps.later

-- Export maybe_later via module to avoid global state
local deps_utils = require("kyleking.deps_utils")
deps_utils.maybe_later = maybe_later

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

local now, later = MiniDeps.now, MiniDeps.later

-- Test runner (extracted to separate module for maintainability)
local test_runner = require("kyleking.utils.test_runner")

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
            function() test_runner.run_all_tests(false, false) end,
            { desc = "Run all Mini.test test files" }
        )

        vim.api.nvim_create_user_command(
            "RunFailedTests",
            function() test_runner.run_failed_tests() end,
            { desc = "Run only failed tests from last run" }
        )

        vim.api.nvim_create_user_command(
            "RunTestsParallel",
            function() test_runner.run_tests_parallel(false) end,
            { desc = "Run tests in parallel with worker pool" }
        )

        vim.api.nvim_create_user_command("RunTestsRandom", function(opts)
            local seed = tonumber(opts.args) or os.time()
            test_runner.run_all_tests(false, true, seed)
        end, { nargs = "?", desc = "Run tests in random order (optional seed)" })

        vim.api.nvim_create_user_command("RunTestsParallelRandom", function(opts)
            local seed = tonumber(opts.args) or os.time()
            test_runner.run_tests_parallel(true, seed)
        end, { nargs = "?", desc = "Run tests in parallel with random order (optional seed)" })

        vim.api.nvim_create_user_command(
            "RunTestCI",
            function() test_runner.run_ci_tests() end,
            { desc = "Run CI-safe tests (no external tool dependencies)" }
        )

        vim.api.nvim_create_user_command(
            "RunTestFast",
            function() test_runner.run_fast_tests() end,
            { desc = "Run fast tests (excludes subprocess-heavy tests, ~10-15s)" }
        )

        -- Add keymaps to run tests
        vim.keymap.set(
            "n",
            "<leader>ta",
            function() test_runner.run_all_tests(false, false) end,
            { desc = "Run all tests" }
        )
        vim.keymap.set("n", "<leader>tf", function() test_runner.run_failed_tests() end, { desc = "Run failed tests" })
        vim.keymap.set(
            "n",
            "<leader>tq",
            function() test_runner.run_fast_tests() end,
            { desc = "Run fast tests (quick)" }
        )
        vim.keymap.set(
            "n",
            "<leader>tp",
            function() test_runner.run_tests_parallel(false) end,
            { desc = "Run tests parallel" }
        )
        vim.keymap.set(
            "n",
            "<leader>tr",
            function() test_runner.run_all_tests(false, true, os.time()) end,
            { desc = "Run tests random" }
        )
    end
end)

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
