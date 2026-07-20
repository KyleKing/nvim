-- Plugin management via Neovim's built-in vim.pack (see lua/kyleking/pack.lua for the
-- thin add/now/later compatibility layer). Plugin revisions are tracked by vim.pack's
-- lockfile at stdpath("config")/nvim-pack-lock.json.

local pack = require("kyleking.pack")

-- Bootstrap the mini.nvim bundle first: modules (mini.test, mini.statusline, mini.icons)
-- are needed during startup. vim.pack installs it on first run.
pack.add("nvim-mini/mini.nvim")

-- For testing: maybe_later uses now() when NVIM_TEST_SYNC=1, otherwise later()
-- This provides explicit control over plugin loading during tests.
local maybe_later = vim.env.NVIM_TEST_SYNC and pack.now or pack.later

-- Export maybe_later via module to avoid global state
local deps_utils = require("kyleking.deps_utils")
deps_utils.maybe_later = maybe_later

require("kyleking.deps.bars-and-lines")
require("kyleking.deps.buffer")
require("kyleking.deps.cmdline")
require("kyleking.deps.color")
require("kyleking.deps.colorscheme")
require("kyleking.deps.editing-support")
require("kyleking.deps.file-explorer")
require("kyleking.deps.formatting")
require("kyleking.deps.fuzzy-finder")
require("kyleking.deps.git")
require("kyleking.deps.input")
require("kyleking.deps.keybinding")
require("kyleking.deps.keymap")
require("kyleking.deps.lsp")
require("kyleking.deps.motion")
require("kyleking.deps.search")
require("kyleking.deps.snippets")
require("kyleking.deps.split-and-window")
require("kyleking.deps.syntax")
require("kyleking.deps.terminal-integration")
require("kyleking.deps.utility")
require("kyleking.deps.local")

local now = pack.now

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

        -- Test keybindings: Only <leader>tf for re-running failures
        -- For full test runs, use mise: `mise run test`, `mise run test:parallel`, etc.
        vim.keymap.set("n", "<leader>tf", function() test_runner.run_failed_tests() end, { desc = "Run failed tests" })
    end
end)
