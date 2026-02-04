return {
    title = "VCS Integration (git/jj)",
    see_also = { "MiniDiff", "MiniGit" },
    desc = "VCS-agnostic operations (auto-detects jj or git): inline diff signs, hunk operations, status/log/blame/commit commands. Works seamlessly in both git and jj repositories.",
    source = "lua/kyleking/deps/git.lua",

    notes = {
        "**Hunk operations** (work in both git and jj):",
        "- `<leader>gha` - Apply hunk (stage changes)",
        "- `<leader>ghr` - Reset hunk (discard changes)",
        "- `]h` / `[h` - Jump to next/previous hunk",
        "- `]H` / `[H` - Jump to last/first hunk",
        "",
        "**VCS commands** (auto-detect git or jj):",
        "- `<leader>gs` - Status (git status / jj status)",
        "- `<leader>gl` - Log (git log / jj log)",
        "- `<leader>gb` - Blame/show at cursor",
        "- `<leader>gh` - Range history",
        "- `<leader>gd` - Diff",
        "- `<leader>gc` - Commit message prompt (git commit / jj describe)",
        "",
        "**Display toggles**:",
        "- `<leader>ugd` - Toggle diff overlay (full inline diff)",
        "",
        "**Diffview plugin**:",
        "- `:DiffviewOpen` - Side-by-side diff viewer",
        "- `:DiffviewClose` - Close diffview",
        "",
        "Diff signs: added (green), deleted (red), modified (yellow). Statusline shows VCS type and branch/workspace.",
    },

    grammars = {
        {
            pattern = "<leader>gh[ar]",
            desc = "Hunk operations",
            tests = {
                {
                    name = "hunk keybindings exist",
                    expect = {
                        fn = function(_ctx)
                            local MiniTest = require("mini.test")
                            local helpers = require("tests.helpers")

                            -- Verify hunk operation keymaps exist
                            MiniTest.expect.equality(helpers.check_keymap("n", "<leader>gha"), true, "apply hunk")
                            MiniTest.expect.equality(helpers.check_keymap("n", "<leader>ghr"), true, "reset hunk")
                            MiniTest.expect.equality(helpers.check_keymap("n", "]h"), true, "next hunk")
                            MiniTest.expect.equality(helpers.check_keymap("n", "[h"), true, "prev hunk")
                        end,
                    },
                },
            },
        },
        {
            pattern = "<leader>g[slbdhc]",
            desc = "VCS commands",
            tests = {
                {
                    name = "vcs command keybindings exist",
                    expect = {
                        fn = function(_ctx)
                            local MiniTest = require("mini.test")
                            local helpers = require("tests.helpers")

                            -- Verify VCS command keymaps exist
                            MiniTest.expect.equality(helpers.check_keymap("n", "<leader>gs"), true, "status")
                            MiniTest.expect.equality(helpers.check_keymap("n", "<leader>gl"), true, "log")
                            MiniTest.expect.equality(helpers.check_keymap("n", "<leader>gb"), true, "blame")
                            MiniTest.expect.equality(helpers.check_keymap("n", "<leader>gd"), true, "diff")
                            MiniTest.expect.equality(helpers.check_keymap("n", "<leader>gc"), true, "commit")
                        end,
                    },
                },
            },
        },
        {
            pattern = "<leader>ugd",
            desc = "Toggle diff overlay",
            tests = {
                {
                    name = "config check",
                    expect = {
                        fn = function(_ctx)
                            local MiniDiff = require("mini.diff")
                            local MiniTest = require("mini.test")
                            MiniTest.expect.equality(type(MiniDiff.toggle_overlay), "function")
                            MiniTest.expect.equality(MiniDiff.config.view.style, "number")
                        end,
                    },
                },
            },
        },
    },
}
