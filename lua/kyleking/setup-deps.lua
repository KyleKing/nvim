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
            function() test_runner.run_all_tests(false) end,
            { desc = "Run all Mini.test test files" }
        )

        vim.api.nvim_create_user_command(
            "RunFailedTests",
            function() test_runner.run_failed_tests() end,
            { desc = "Run only failed tests from last run" }
        )

        -- Add keymaps to run tests
        vim.keymap.set("n", "<leader>ta", function() test_runner.run_all_tests(false) end, { desc = "Run all tests" })
        vim.keymap.set("n", "<leader>tf", function() test_runner.run_failed_tests() end, { desc = "Run failed tests" })
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
