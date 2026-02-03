return {
    title = "Git (mini.diff, mini.git, diffview)",
    see_also = { "MiniDiff", "MiniGit" },
    desc = "Inline diff signs in the sign column (mini.diff), statusline git branch (mini.git), and side-by-side diff viewing (diffview.nvim).",
    source = "lua/kyleking/deps/git.lua",

    notes = {
        "`<leader>ugd` Toggle git diff overlay (full inline diff)",
        "`:DiffviewOpen` Open side-by-side diff viewer",
        "`:DiffviewClose` Close diffview",
        "",
        "Shows added (green), deleted (red), and modified (yellow) lines in sign column.",
        "Statusline displays current git branch from mini.git.",
    },

    grammars = {
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
                            MiniTest.expect.equality(MiniDiff.config.view.style, "sign")
                        end,
                    },
                },
            },
        },
    },
}
